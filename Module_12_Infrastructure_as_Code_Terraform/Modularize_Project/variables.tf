variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "modular-network-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_pair_name" {
  type = string
}

variable "allowed_http_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "allowed_ssh_cidr_blocks" {
  type    = list(string)
  default = ["203.0.113.0/24"]

  validation {
    condition     = !contains(var.allowed_ssh_cidr_blocks, "0.0.0.0/0")
    error_message = "Do not allow SSH from 0.0.0.0/0. Use a trusted source range."
  }
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}