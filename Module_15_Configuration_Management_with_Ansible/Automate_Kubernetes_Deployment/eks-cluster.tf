resource "aws_eks_cluster" "example" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = values(aws_subnet.private)[*].id
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
  ]

  tags = merge(local.common_tags, { Name = var.cluster_name })
}