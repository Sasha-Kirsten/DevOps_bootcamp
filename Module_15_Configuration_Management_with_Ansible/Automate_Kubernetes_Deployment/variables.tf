variable "aws_region" {
  description = "AWS Region in which to create the EKS environment."
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "bootcamp-eks"
}

variable "kubernetes_version" {
  description = "Supported EKS Kubernetes version selected for the cluster."
  type        = string
  default     = "1.31"
}

variable "environment" {
  description = "Environment tag applied to all resources."
  type        = string
  default     = "development"
}

variable "application" {
  description = "Application or project tag applied to all resources."
  type        = string
  default     = "devops-bootcamp"
}

variable "vpc_cidr" {
  description = "CIDR range assigned to the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet hosting the NAT gateway."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_availability_zone" {
  description = "Availability Zone for the public NAT gateway subnet."
  type        = string
  default     = "us-west-2a"
}

variable "private_subnets" {
  description = "Private worker-node subnets keyed by Availability Zone. At least two AZs are required by EKS."
  type        = map(string)
  default = {
    us-west-2a = "10.0.1.0/24"
    us-west-2b = "10.0.2.0/24"
  }

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "EKS requires private subnets in at least two Availability Zones."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types allowed in the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}
