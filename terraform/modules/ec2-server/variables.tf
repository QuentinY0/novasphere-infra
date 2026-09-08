variable "name" {
  description = "Nom logique du serveur"
  type        = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "admin_cidr" {
  description = "CIDR autorise en SSH"
  type        = string
  validation {
    condition     = var.admin_cidr != "0.0.0.0/0"
    error_message = "L'acces SSH ouvert a 0.0.0.0/0 est interdit."
  }
}

variable "open_ports" {
  type    = list(number)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
