terraform {
  required_version = ">= 1.15.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "NovaSphere"
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }
}

provider "random" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "novasphere-${var.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs                     = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets          = ["10.0.1.0/24", "10.0.2.0/24"]
  map_public_ip_on_launch = true

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

resource "aws_security_group" "alb" {
  name        = "novasphere-${var.environment}-alb-sg"
  description = "Autorise le trafic HTTP entrant pour ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Tout trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance" {
  name        = "novasphere-${var.environment}-instance-sg"
  description = "Autorise le trafic venant uniquement de ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP uniquement depuis ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Tout trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "db_password" {
  type      = string
  sensitive = true
  ephemeral = true
  default   = "SecretInitProd2026!"
}

resource "aws_ssm_parameter" "db_password" {
  name             = "/novasphere/${var.environment}/db_password"
  type             = "SecureString"
  value_wo         = var.db_password
  value_wo_version = 1
  description      = "Mot de passe applicatif"
}

resource "aws_launch_template" "app" {
  name_prefix   = "novasphere-${var.environment}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance.id]
  }

  user_data = filebase64("${path.module}/bootstrap.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "novasphere-${var.environment}-asg-instance"
    }
  }
}

resource "aws_lb_target_group" "app" {
  name     = "novasphere-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "main" {
  name               = "novasphere-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "novasphere-${var.environment}-asg-"
  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
