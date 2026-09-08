terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Project     = "NovaSphere"
    }
  }
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136540187036"]
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "novasphere-${var.environment}"
  cidr = "10.0.0.0/16"

  azs            = ["eu-west-3a", "eu-west-3b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway      = false
  enable_vpn_gateway      = false
  map_public_ip_on_launch = true
}

resource "aws_security_group" "alb" {
  name   = "novasphere-${var.environment}-alb"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name   = "novasphere-${var.environment}-web"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "novasphere-${var.environment}-"
  image_id      = data.aws_ami.debian.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = base64encode(file("${path.module}/bootstrap.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "novasphere-${var.environment}-web"
    }
  }
}

resource "aws_lb" "web" {
  name               = "novasphere-${var.environment}"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "web" {
  name     = "novasphere-${var.environment}-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "novasphere-${var.environment}-web"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "novasphere-${var.environment}-web"
    propagate_at_launch = true
  }
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

variable "db_password" {
  description = "Mot de passe applicatif"
  type        = string
  ephemeral   = true
  default     = "TemporaryPass123!"
}

resource "aws_ssm_parameter" "db_password" {
  name             = "/novasphere/${var.environment}/db_password"
  type             = "SecureString"
  value_wo         = var.db_password
  value_wo_version = 1
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "novasphere-${var.environment}-web"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy" "read_secrets" {
  name = "read-secrets"
  role = aws_iam_role.web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = "arn:aws:ssm:eu-west-3:*:parameter/novasphere/${var.environment}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "novasphere-${var.environment}-web"
  role = aws_iam_role.web.name
}
