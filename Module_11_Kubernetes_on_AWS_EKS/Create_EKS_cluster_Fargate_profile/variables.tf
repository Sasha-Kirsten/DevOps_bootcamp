variable "aws_region" {
  description = "AWS Region containing the existing EKS cluster."
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster that receives the Fargate profile."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where Fargate Pods will be scheduled."
  type        = list(string)
}

variable "project_name" {
  description = "Short identifier used in Fargate profile and IAM role names."
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "Deployment environment used for names and tags."
  type        = string
  default     = "dev"
}