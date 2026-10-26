variable "aws_region" {
  description = "AWS Region in which to create the EKS environment."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Name assigned to the EKS cluster."
  type        = string
  default     = "bootcamp-eks-demo"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Confirm availability in the selected Region before applying."
  type        = string
  default     = "1.31"
}

variable "environment" {
  description = "Environment tag applied to provisioned resources."
  type        = string
  default     = "development"
}

variable "vpc_cidr" {
  description = "CIDR range assigned to the VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones used by the VPC. EKS requires at least two."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least two Availability Zones for EKS."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR ranges for EKS worker nodes."
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "Provide one private subnet CIDR for each Availability Zone."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR ranges for NAT gateway and public load balancers."
  type        = list(string)
  default     = ["10.30.101.0/24", "10.30.102.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "Provide one public subnet CIDR for each Availability Zone."
  }
}

variable "node_instance_types" {
  description = "Instance types permitted in the managed EKS node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API endpoint is publicly accessible. Keep false unless a restricted public CIDR design is added."
  type        = bool
  default     = false
}