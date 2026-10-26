# Terraform & AWS EKS

## Demo project

**Demo Project:** Terraform & AWS EKS  
**Technologies Used:** Terraform, AWS EKS, Docker, Linux, Git  
**Project Description:** Automate provisioning of an Amazon EKS cluster and its supporting AWS network infrastructure with Terraform.

This project defines a repeatable Amazon EKS learning environment. Terraform creates a two-Availability-Zone VPC, public and private subnets, NAT egress, an EKS control plane, managed worker nodes, required EKS add-ons, control-plane logging, and consistent resource tags.

Docker is used to package application workloads that can be deployed **after** the cluster is available; Docker does not provision AWS infrastructure. Linux is the local or CI runtime for Terraform and Kubernetes tooling, while Git provides reviewable infrastructure version control.

## Architecture

- **Region:** `eu-central-1` by default.
- **Network:** VPC with two public and two private subnets across two Availability Zones.
- **Egress:** one NAT gateway for a lower-cost development baseline.
- **Cluster:** Amazon EKS with private API access enabled and public API access disabled by default.
- **Compute:** a managed node group using two `t3.medium` nodes by default, scalable from one to three nodes.
- **Platform capabilities:** IAM Roles for Service Accounts (IRSA), CoreDNS, kube-proxy, Amazon VPC CNI, and EKS Pod Identity Agent.
- **Observability:** API, audit, and authenticator control-plane logs.

The single NAT gateway is a deliberate learning/cost trade-off. Production workloads should use NAT gateways per Availability Zone, a remote encrypted Terraform state backend with locking, appropriate backups, and organization-specific access controls.

## Repository layout

| File | Purpose |
| --- | --- |
| `provider.tf` | Terraform and AWS provider requirements, default tags |
| `main.tf` | VPC, public/private subnets, routing, and NAT via the VPC module |
| `eks-cluster.tf` | EKS control plane, add-ons, IRSA, and managed node group |
| `variable.tf` | Typed and validated project inputs |
| `outputs.tf` | Cluster information and a post-apply kubeconfig command |
| `terraform.tfvars.example` | Non-secret local configuration template |

## Prerequisites

- Terraform `1.5` or later
- AWS CLI authenticated through IAM Identity Center, an assumed role, or another standard AWS credential provider
- An AWS account with sufficient permissions to plan and, only if intended, provision VPC and EKS resources
- `kubectl` and AWS CLI v2 for post-deployment cluster access

Do **not** store AWS access keys in this repository, `terraform.tfvars`, or Terraform state. Use short-lived credentials and a dedicated development account whenever possible.

## Verify safely

The following checks download provider/module schemas and validate the Terraform configuration. They do not create AWS resources:

```text
terraform fmt -check -recursive
terraform init -backend=false -input=false -upgrade
terraform validate -no-color
```

For local customization, copy `terraform.tfvars.example` to `terraform.tfvars` and adjust non-secret values. The real `terraform.tfvars` file is ignored by Git.

## Plan and deploy deliberately

After verifying the active AWS account and Region, generate a reviewed plan:

```text
aws sts get-caller-identity
terraform plan -out=tfplan
terraform show tfplan
```

`terraform plan` reads AWS account metadata but does not create infrastructure. `terraform apply tfplan` creates billable AWS resources and must only be run after reviewing the plan in an approved development account. An EKS control plane, NAT gateway, public IPv4 address, and EC2 worker nodes all incur charges.

After a successful apply, configure access from a network path that can reach the private EKS endpoint:

```text
aws eks update-kubeconfig --region eu-central-1 --name bootcamp-eks-demo
kubectl get nodes
```

When the learning environment is no longer required, remove it to stop charges:

```text
terraform destroy
```

## Recruiter walkthrough

1. Start with `main.tf` to explain the multi-AZ network and private worker-node design.
2. Open `eks-cluster.tf` to show managed node groups, add-ons, IRSA, logging, and private-by-default API access.
3. Show the successful `terraform fmt`, initialization, and validation output.
4. If an approved disposable AWS account is available, present a reviewed `terraform plan` or deployment evidence without exposing account IDs, endpoints, credentials, or state.
5. Explain how a Docker image would be deployed to this cluster using Kubernetes manifests or Helm once the infrastructure is ready.

## References

- [Terraform AWS EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Terraform AWS VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [Amazon EKS documentation](https://docs.aws.amazon.com/eks/)