variable "aws_region" {
  description = "AWS Region in which to create the EKS cluster."
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names and tags, such as dev or sandbox."
  type        = string
}

variable "kubernetes_version" {
  description = "Currently supported EKS Kubernetes version."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "At least two Availability Zones in aws_region. Each needs one public and one private subnet CIDR."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least two Availability Zones for EKS high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs in the same order as availability_zones."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs in the same order as availability_zones."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS API endpoint is reachable publicly. Restrict its CIDRs when enabled."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint when endpoint_public_access is true."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types allowed in the managed node group."
  type        = list(string)
}

variable "node_capacity_type" {
  description = "Managed node group capacity type: ON_DEMAND or SPOT."
  type        = string

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size_gib" {
  description = "Root EBS volume size for each managed node, in GiB."
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of managed worker nodes."
  type        = number
}

variable "node_desired_size" {
  description = "Initial desired number of managed worker nodes."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of managed worker nodes."
  type        = number
}

variable "tags" {
  description = "Additional tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}