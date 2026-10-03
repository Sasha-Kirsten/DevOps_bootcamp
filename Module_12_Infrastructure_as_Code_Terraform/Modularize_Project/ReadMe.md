# Modular AWS Infrastructure with Terraform

## Overview

This project demonstrates how to split an AWS network into focused Terraform modules while keeping shared orchestration in a root module. It creates a learning environment with a VPC, public and private subnets, an Internet Gateway, a NAT Gateway, route tables, security groups, and two EC2 instances.

The design is intentionally small but follows an important module rule: **a child module receives all of its dependencies as inputs and returns only the outputs its caller needs**. Child modules do not configure providers, embed credentials, or reference resources in their parent module.

> **Cost notice:** This configuration provisions a NAT Gateway and Elastic IP, which can incur charges while they exist. Review the plan carefully and run `terraform destroy` after the exercise.

## Architecture

```text
Internet
	|
Internet Gateway
	|
Public route table ── Public subnet ── Web EC2 instance
												 |
										NAT Gateway + Elastic IP
												 |
Private route table ── Private subnet ── Private EC2 instance
```

The public instance runs NGINX. The private instance has no public IP address; it can use the NAT Gateway for outbound updates and only accepts SSH traffic from the public instance security group.

## Module Contracts

| Module | Responsibility | Key inputs | Key outputs |
| --- | --- | --- | --- |
| `modules/subnet` | Creates public and private subnets in one Availability Zone. | VPC ID, Availability Zone, subnet CIDRs, tags. | Public and private subnet IDs. |
| `modules/route_table` | Creates public/private default routes and associates them with the provided subnets. | VPC, Internet Gateway, NAT Gateway, subnet IDs, tags. | Public and private route-table IDs. |
| Root module | Owns the provider, VPC, gateways, Elastic IP, security groups, EC2 instances, and module composition. | Project variables and module outputs. | VPC, subnet, and web-server outputs. |

## Project Layout

```text
Modularize_Project/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── modules/
│   ├── subnet/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── route_table/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── ReadMe.md
```

## Prerequisites

- Terraform 1.5 or later.
- An AWS account and a least-privilege IAM identity.
- AWS credentials supplied through an AWS profile, environment variables, workload identity, or an assumed role. Never put credentials in Terraform files.
- An existing EC2 key pair in the target AWS Region.

## Configure Inputs

Copy the safe template and set values for your environment:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Before applying, replace:

- `key_pair_name` with a key pair that exists in the selected Region.
- `203.0.113.10/32` with your current trusted public IP address or approved administrator range.
- `allowed_http_cidr_blocks` if the NGINX page should not be public.

`terraform.tfvars` is ignored by Git. It is for non-secret local configuration only; it must not contain AWS credentials.

## Run the Project

Execute these commands from this directory:

```sh
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan before applying:

```sh
terraform apply
```

After a successful apply, retrieve the application address:

```sh
terraform output -raw web_url
```

## Security and Operations Notes

- SSH from `0.0.0.0/0` is rejected by variable validation. Keep SSH limited to known ranges or use AWS Systems Manager Session Manager instead.
- The public instance allows HTTP from the configured CIDRs. Restrict this before using the design beyond a demonstration.
- The configuration discovers a current Amazon Linux 2023 x86_64 AMI and uses `dnf` in its user-data scripts.
- Add a remote encrypted state backend with locking before collaborating with others.
- Commit `.terraform.lock.hcl` after `terraform init` so provider versions are reproducible.

## Cleanup

Remove the learning resources as soon as they are no longer needed:

```sh
terraform destroy
```

Read the destroy plan before confirming it, especially when working in a shared account.

## Resources

- [Terraform module documentation](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon VPC documentation](https://docs.aws.amazon.com/vpc/)