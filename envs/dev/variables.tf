variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Nom de l'environnement (dev, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Trigramme du propriétaire"
  type        = string
  default     = "hyi"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}
