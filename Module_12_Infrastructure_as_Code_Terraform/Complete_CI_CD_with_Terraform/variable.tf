variable "aws_region" {
  description = "AWS Region in which to create the learning environment."
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment label applied to resources."
  type        = string
  default     = "development"
}

variable "vpc_name" {
  description = "Name prefix for network resources."
  type        = string
  default     = "cicd-demo"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public EC2 subnet."
  type        = string
  default     = "10.40.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the public subnet and EC2 instance."
  type        = string
  default     = "eu-central-1a"
}

variable "ami_id" {
  description = "AMI ID for an Amazon Linux 2023 EC2 host in the selected Region."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used for the application host."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key-pair name. Leave null when using Systems Manager rather than SSH."
  type        = string
  default     = null
  nullable    = true
}

variable "ssh_ingress_cidr" {
  description = "Trusted CIDR permitted to SSH to the learning instance. Use a single trusted IP range, never 0.0.0.0/0."
  type        = string
  default     = "127.0.0.1/32"
}

variable "application_port" {
  description = "Public TCP port exposed by the Java application."
  type        = number
  default     = 8080

  validation {
    condition     = var.application_port > 0 && var.application_port < 65536
    error_message = "application_port must be between 1 and 65535."
  }

}

