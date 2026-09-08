variable "environment" {
  type    = string
  default = "prod"
}

variable "owner" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
