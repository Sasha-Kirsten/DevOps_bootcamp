# Automating AWS Infrastructure with Terraform

## Overview

This project introduces the automation of AWS infrastructure using Terraform and Infrastructure as Code (IaC). The intended environment contains a VPC, public and private subnets, internet access, a NAT gateway, route tables, security groups, and EC2 instances.

Terraform describes the desired infrastructure in `.tf` files. It then compares that configuration with the current AWS environment and creates a plan before making any change. This makes infrastructure easier to review, repeat, and manage as a team.

> **Learning project:** This configuration creates billable AWS resources, including a NAT gateway, Elastic IP address, and two EC2 instances. Review the plan and destroy the environment when you finish the exercise.

## Intended Architecture

```text
Internet
	│
Internet Gateway
	│
Public Route Table ── Public Subnet ── Public EC2 instance
									 │
							  NAT Gateway
									 │
Private Route Table ── Private Subnet ── Private EC2 instance
```

The public EC2 instance can receive permitted inbound traffic from the internet. The private EC2 instance does not receive a public IP address; it can use the NAT gateway for outbound access, for example to download operating-system updates.

## Components

| Component | Purpose |
| --- | --- |
| VPC | Provides the private network boundary for all application resources. |
| Internet gateway | Connects the VPC's public route table to the internet. |
| Public subnet | Hosts internet-facing resources, such as a public EC2 instance and NAT gateway. |
| Private subnet | Hosts internal resources that should not be directly accessible from the internet. |
| Elastic IP | Gives the NAT gateway a public address. |
| NAT gateway | Lets private-subnet resources initiate outbound internet connections. |
| Route tables | Control where subnet traffic is sent: to the internet gateway or the NAT gateway. |
| Security groups | Stateful virtual firewalls that control inbound and outbound traffic for EC2 instances. |
| EC2 instances | Provide compute capacity for the public-facing and private workloads. |

## Prerequisites

Before working through the project, make sure you have:

- An AWS account and an IAM identity with only the permissions needed for this learning environment.
- Terraform installed locally. Verify the installation with `terraform version`.
- AWS CLI installed and authenticated, or AWS credentials provided securely through environment variables, a profile, or workload identity.
- An existing EC2 key pair in the target AWS Region if the configuration creates an EC2 instance with `key_name`.
- Basic understanding of AWS networking and the difference between public and private subnets.

> **Never** commit AWS access keys or secret keys into `main.tf`, `variables.tf`, Git, screenshots, or documentation.

## Project Files

| File | Purpose |
| --- | --- |
| `main.tf` | Defines the AWS provider, VPC, routing, security groups, AMI lookup, and EC2 instances. |
| `variables.tf` | Declares the reusable network, instance, access, and tagging inputs. |
| `versions.tf` | Pins compatible Terraform and AWS provider versions. |
| `outputs.tf` | Exposes useful VPC and EC2 identifiers and the public web URL. |
| `terraform.tfvars.example` | Safe template for the required key-pair name and permitted CIDR blocks. |
| `.gitignore` | Prevents local state and real `terraform.tfvars` files from entering Git. |
| `ReadMe.md` | Explains the architecture, workflow, and safety checks for this project. |

## Implementation Steps

### 1. Create the Terraform configuration files

Start with separate files for resources, variables, outputs, and version constraints. Terraform loads all `.tf` files in one directory, so splitting files improves readability without changing how Terraform evaluates the configuration.

Suggested layout:

```text
Automative_AWS_Infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
└── ReadMe.md
```

### 2. Configure reusable input variables

Replace hard-coded values with variables for values that differ between environments. Typical variables for this project include:

- AWS Region
- VPC CIDR block
- Public and private subnet CIDR blocks
- Availability Zone
- Allowed SSH and HTTP source CIDR blocks
- EC2 AMI ID and instance type
- EC2 key-pair name
- Resource name and environment tags

The declarations are already implemented in `variables.tf`. Copy the safe example inputs before planning, then replace the key-pair name and documentation IP range with real values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` is ignored by Git. Do not use it for credentials; authenticate AWS through a profile, environment variables, or workload identity.

### 3. Build the network in dependency order

Terraform automatically builds a dependency graph when one resource refers to another. The intended resource order is still useful for understanding the design:

1. Create the VPC with a valid non-overlapping CIDR block, such as `10.0.0.0/16`.
2. Create public and private subnets inside the VPC.
3. Attach an internet gateway to the VPC.
4. Allocate an Elastic IP and create a NAT gateway in the public subnet.
5. Create a public route table with a default route (`0.0.0.0/0`) to the internet gateway.
6. Create a private route table with a default route to the NAT gateway.
7. Associate each route table with its matching subnet.
8. Create narrowly scoped security groups for the EC2 instances.
9. Create the public and private EC2 instances in their appropriate subnets.

### 4. Configure security groups carefully

Security groups act as stateful firewalls. Grant only the traffic that the application needs:

- Allow HTTP (`80/TCP`) to the public instance only when a web service is intended to be public.
- Restrict SSH (`22/TCP`) to a known administrator IP range, a bastion host, or a secure access service. Do not allow SSH from `0.0.0.0/0` in a real environment.
- Allow private-instance traffic from the public instance's security group only when the application architecture requires it.
- Keep outbound rules minimal where organisational policies require strict egress controls.

Use security-group IDs with network interfaces or EC2 instances. Security groups are not attributes of subnets or route tables.

### 5. Initialise, format, validate, and plan

Run these commands from this project directory before applying any changes:

```bash
# Download the AWS provider and initialise Terraform
terraform init

# Apply standard Terraform formatting
terraform fmt

# Validate Terraform syntax and configuration references
terraform validate

# Preview the AWS resources that Terraform would change
terraform plan
```

`terraform plan` does not create AWS resources. Read the plan carefully and check for unexpected replacements or deletions.

### 6. Apply and verify the environment

After a successful review of the plan, apply the configuration:

```bash
terraform apply
```

Terraform asks for confirmation before applying unless an automation pipeline supplies an approved plan. After deployment, verify the VPC, route tables, security groups, and EC2 connectivity in AWS. Terraform prints a `web_url` output for the NGINX page on the public instance; the private instance has no public IP and accepts SSH only from the public instance security group.

### 7. Clean up learning resources

AWS resources, especially NAT gateways and Elastic IP addresses, can create ongoing charges. When this learning environment is no longer needed, remove only the resources managed by this Terraform project:

```bash
terraform destroy
```

Review the destroy plan before confirming it. Do not run this command against an environment containing resources that must be retained.

## Before Applying

Complete this safety checklist before creating AWS resources:

- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`.
- [ ] Replace `key_pair_name` with an existing EC2 key pair in the selected AWS Region.
- [ ] Replace `203.0.113.10/32` with your current trusted public IP or approved administrator CIDR range.
- [ ] Review `allowed_http_cidr_blocks`; `0.0.0.0/0` makes the demo web page public.
- [ ] Confirm AWS authentication works without credentials in Terraform files, for example with `aws sts get-caller-identity`.
- [ ] Confirm you accept the ongoing NAT gateway and Elastic IP charges while this project exists.
- [ ] Review `terraform plan` for the exact Region, AMI, tags, and resources before applying.

The configuration discovers the latest Amazon Linux 2023 x86_64 AMI published by Amazon in the chosen Region. Its user-data scripts use `dnf`, matching that operating system.

## Terraform and AWS Best Practices

- Store Terraform code in Git and review infrastructure changes through pull requests.
- Use a remote, encrypted, versioned state backend with locking when collaborating with others.
- Use separate state files and credentials for development, test, staging, and production.
- Pin Terraform and AWS provider versions to tested releases.
- Run `terraform fmt -check`, `terraform validate`, and `terraform plan` in continuous integration.
- Apply production changes only from a protected CI/CD pipeline with an approved service identity.
- Use least-privilege IAM permissions and avoid long-lived access keys.
- Add consistent tags such as `Name`, `Environment`, `Project`, and `Owner`.

## Getting Started

1. Install Terraform and authenticate to AWS without putting credentials in source files.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and complete the **Before Applying** checklist.
3. Run `terraform init`, `terraform fmt`, `terraform validate`, and `terraform plan`.
4. Review the plan, apply it only when it matches the intended architecture, and verify the deployed resources.
5. Run `terraform destroy` when the practice environment is no longer required.

## Resources

- [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform language documentation](https://developer.hashicorp.com/terraform/language)
- [AWS VPC documentation](https://docs.aws.amazon.com/vpc/)
- [AWS security-group documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)

## Topics to Add Later

- Remote Terraform state in an encrypted S3 bucket with state locking
- Multiple Availability Zones for higher availability
- A bastion host or AWS Systems Manager Session Manager for private-instance access
- A CI/CD pipeline that validates and applies Terraform safely
- Cost monitoring and budget alerts for the NAT gateway and EC2 instances
