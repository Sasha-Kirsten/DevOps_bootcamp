variable "vpc_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}