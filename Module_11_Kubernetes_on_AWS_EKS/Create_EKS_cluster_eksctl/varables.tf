variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "" # TODO
}

variable "project_name" {
  description = "Short project identifier used in names and tags."
  type        = string
  default     = "" # TODO
}

variable "environment" {
  description = "Deployment environment, for example dev or sandbox."
  type        = string
  default     = "" # TODO
}

variable "cluster_version" {
  description = "A currently supported EKS Kubernetes version."
  type        = string
  default     = "" # TODO
}

variable "node_instance_type" {
  description = "Managed node group instance type."
  type        = string
  default     = "" # TODO
}

variable "node_min_size" {
  type    = number
  default = 0 # TODO
}

variable "node_desired_size" {
  type    = number
  default = 0 # TODO
}

variable "node_max_size" {
  type    = number
  default = 0 # TODO
}

