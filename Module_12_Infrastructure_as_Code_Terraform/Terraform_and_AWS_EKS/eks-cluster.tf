module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.1.3"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_private_access = true
  endpoint_public_access  = var.endpoint_public_access
  enabled_log_types       = ["api", "audit", "authenticator"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}
    "eks-pod-identity-agent" = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  tags = local.common_tags
}

