# Amazon EKS managed node group with Terraform

## Overview

This project provisions a small but realistic Amazon EKS foundation using native Terraform resources. It creates:

- A VPC with two public and two private subnets across separate Availability Zones.
- An internet gateway, one NAT gateway, and route tables for outbound node access.
- Separate least-privilege IAM roles for the EKS control plane and EC2 worker nodes.
- An EKS control plane with API, audit, and authenticator logs enabled.
- A managed EKS node group in private subnets with configurable instance types and autoscaling limits.

The configuration deliberately keeps account-specific choices out of resource blocks. Copy `terraform.tfvars.example` to `terraform.tfvars`, then replace every `replace-with-...` value and adjust the example CIDRs to fit your network plan.

## Architecture

```text
Internet
	|
Internet gateway
	|
Public subnets (two AZs) ---- NAT gateway
										  |
								 Private subnets (two AZs)
										  |
						EKS managed node group / EC2 nodes
										  |
							  Amazon EKS control plane
```

The control plane uses all four subnets for EKS networking. Worker nodes are deliberately scheduled only in the private subnets.

## Prerequisites

- Terraform `>= 1.6`.
- AWS CLI configured with credentials permitted to create EKS, EC2/VPC, IAM, CloudWatch Logs, and Elastic Load Balancing resources.
- `kubectl` and AWS CLI v2 for post-deployment cluster access.
- An AWS Region with at least two usable Availability Zones and support for the selected EKS version and EC2 instance type.

No access keys, account IDs, kubeconfig files, Terraform state, or local `terraform.tfvars` files are committed. The committed `.terraform.lock.hcl` pins provider selections for reproducible initialization.

## Configure your inputs

Create your private variable file:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and provide values for these inputs:

| Input | What you choose |
| --- | --- |
| `aws_region` | AWS Region for every resource. |
| `project_name`, `environment` | Used to construct resource names and consistent tags. |
| `kubernetes_version` | A Kubernetes version currently supported by EKS in your Region. |
| `vpc_cidr` | CIDR for the new VPC. |
| `availability_zones` | At least two AZs in the selected Region. |
| `public_subnet_cidrs`, `private_subnet_cidrs` | One non-overlapping subnet CIDR per AZ; preserve the same list order as `availability_zones`. |
| `endpoint_public_access` | Keep `false` for a private API endpoint, or enable it only with trusted `endpoint_public_access_cidrs`. |
| `node_instance_types` | Instance type(s) approved for your account and workload. |
| `node_capacity_type` | `ON_DEMAND` for predictable capacity or `SPOT` for lower cost with interruption tolerance. |
| `node_*_size`, `node_disk_size_gib` | Worker-node autoscaling boundaries and root-volume size. |
| `tags` | Optional ownership, cost-centre, or team tags. |

> The two subnet-CIDR lists must contain exactly one CIDR for each availability zone. All subnet ranges must be contained in `vpc_cidr` and must not overlap.

## Review and deploy

Run the following from this directory after completing `terraform.tfvars`:

```sh
terraform fmt -check
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform state should be moved to a protected remote backend before collaborative or production use. This portfolio template intentionally leaves backend selection to the operator because bucket names, Regions, locking, encryption, and access controls are organization-specific.

## Verify the cluster

After a successful apply, configure local access and inspect the managed node group:

```sh
aws eks update-kubeconfig --region <aws_region> --name <project_name>-<environment>-eks
kubectl get nodes
kubectl get pods --all-namespaces
aws eks describe-nodegroup --cluster-name <project_name>-<environment>-eks --nodegroup-name <project_name>-<environment>-eks-managed-nodes --region <aws_region>
```

Capture the successful plan, `kubectl get nodes` output, and a screenshot of the EKS node group status as portfolio evidence. Do not commit credentials, kubeconfig, or state files with that evidence.

## Security and cost notes

- The Kubernetes API is private by default. If a public endpoint is required, limit `endpoint_public_access_cidrs` to trusted administrative egress CIDRs; never use `0.0.0.0/0` for routine administration.
- Cluster and node permissions are separated into dedicated IAM roles and use AWS-managed EKS policies only.
- Node instances are private; the NAT gateway supplies outbound access for image pulls and updates.
- This configuration creates billable AWS resources, including the EKS control plane, EC2 worker nodes, EBS volumes, NAT gateway, elastic IP, and CloudWatch logs. A single NAT gateway is intentional for a low-cost learning environment, not multi-AZ production resiliency.

## Clean up

When you no longer need the environment, review the destroy plan and remove it:

```sh
terraform destroy
```

Check AWS for manually created resources such as load balancers, persistent volumes, or ECR images before closing the project; Terraform can only remove resources it manages.

## Validation status

The following non-destructive checks passed for this configuration:

- `terraform fmt -check`
- `terraform init -backend=false`
- `terraform validate`

A live `terraform apply` was deliberately not run because it creates chargeable infrastructure.

