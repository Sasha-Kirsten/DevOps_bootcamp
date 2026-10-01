variable "aws_region" {
  description = "AWS Region in which Terraform creates the learning environment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in resource names and tags."
  type        = string
  default     = "terraform-network-lab"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet, contained within the VPC CIDR."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet, contained within the VPC CIDR."
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for both learning instances."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair in the selected AWS Region."
  type        = string
  nullable    = false
}

variable "allowed_http_cidr_blocks" {
  description = "CIDR blocks allowed to access HTTP on the public instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to use SSH on the public instance. Replace the documentation-only default before applying."
  type        = list(string)
  default     = ["203.0.113.0/24"]

  validation {
    condition     = !contains(var.allowed_ssh_cidr_blocks, "0.0.0.0/0")
    error_message = "Do not allow SSH from 0.0.0.0/0. Use your current public IP with a /32 prefix or an approved corporate range."
  }
}

variable "additional_tags" {
  description = "Additional tags merged into every resource tag set."
  type        = map(string)
  default     = {}
}
