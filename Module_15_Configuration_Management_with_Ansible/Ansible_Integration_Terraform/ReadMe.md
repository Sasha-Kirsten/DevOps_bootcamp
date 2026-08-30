# Integrating Ansible with Terraform

## Overview

This project demonstrates a common Infrastructure as Code workflow: Terraform provisions cloud infrastructure, then Ansible configures the new server.

Terraform is responsible for AWS resources such as EC2 instances, networking, and security groups. Ansible is responsible for operating-system configuration and application setup, such as installing Docker, creating users, copying files, and starting services.

```text
Terraform plan and apply
					│
					▼
AWS infrastructure is provisioned
					│
					▼
Terraform local-exec provisioner starts Ansible
					│
					▼
Ansible connects to the new EC2 instance by SSH
					│
					▼
Ansible configures the operating system and application
```

> **Learning project:** The current files are starter examples and cannot be run as they are. Read **Before You Run** before attempting `terraform apply`.

## When to Use This Pattern

Using Terraform and Ansible together is useful when an application needs both cloud infrastructure and server-level configuration:

- Terraform creates an EC2 instance, VPC resources, Elastic IP addresses, and security groups.
- Ansible installs packages, configures services, manages users, and deploys application files.
- The complete environment can be recreated from version-controlled configuration.

Keep each tool focused on its strength. Avoid using Terraform provisioners as the primary long-term configuration-management solution when a CI/CD workflow, cloud-init, immutable images, or a dedicated Ansible pipeline is a better fit.

## Project Files

| File | Purpose |
| --- | --- |
| `main.tf` | Contains the Terraform `null_resource` and local-exec provisioner intended to trigger Ansible after provisioning. |
| `playbook.yaml` | Intended Ansible playbook for configuring the new EC2 instance. It is currently empty. |
| `ReadMe.md` | Explains the intended workflow, prerequisites, verification, and required corrections. |

## Key Terms

| Term | Meaning |
| --- | --- |
| **Terraform resource** | A cloud object Terraform manages, such as an AWS EC2 instance. |
| **`null_resource`** | A Terraform resource often used to run provisioners or react to changes through triggers; it does not create a cloud resource itself. |
| **`local-exec` provisioner** | Runs a command on the machine that executes Terraform, not on the EC2 instance. |
| **Ansible control node** | The machine that runs `ansible-playbook`. In this project, it is the computer or CI/CD runner running Terraform. |
| **Managed node** | The EC2 instance that Ansible connects to and configures. |
| **Inventory** | The list of Ansible target hosts; it can be a file, a dynamic inventory, or a single host followed by a comma. |

## Prerequisites

Before beginning, make sure you have:

- An AWS account and a least-privilege IAM identity for the required resources.
- Terraform installed and authenticated to AWS.
- Ansible installed on the same local machine or CI/CD runner that executes Terraform.
- A complete Terraform configuration that creates an EC2 instance and exports its public IP address.
- An EC2 key pair and its matching private key stored securely outside the Git repository.
- A security group that permits SSH only from the Terraform/Ansible control node or a trusted private network.
- An EC2 AMI and remote username that match the Ansible playbook, such as `ec2-user` for Amazon Linux.
- A completed `playbook.yaml` with the desired configuration tasks.

Verify the local tools:

```bash
terraform version
ansible --version
```

> **Security note:** Never store AWS credentials or SSH private keys in `.tf`, `.yaml`, `.tfvars`, or Git files. Use an AWS profile, IAM role, CI/CD credential store, or another approved secret-management method.

## Implementation Steps

### 1. Create the EC2 infrastructure with Terraform

Create Terraform resources for the network, security group, key pair reference, and EC2 instance. The instance must have an IP address or DNS name reachable by the Ansible control node.

Export the connection address with a Terraform output:

```hcl
output "ec2_public_ip" {
	description = "Public IP address of the configured EC2 instance"
	value       = aws_instance.myapp_server.public_ip
}
```

The exact resource name must match the EC2 resource in the project.

### 2. Write the Ansible playbook

Add the server configuration tasks to `playbook.yaml`. A playbook normally includes:

1. The target hosts, such as `hosts: all` for a small lab or a named group for a larger environment.
2. Privilege escalation with `become: true` for administrative tasks.
3. Idempotent tasks that declare the desired state, such as installing a package or ensuring a service is started.
4. Handlers for service restarts when configuration changes.
5. Tags that let you run a focused part of the configuration.

For example, a Docker host playbook might install Docker, enable and start the Docker service, create a deployment user, and copy a Docker Compose file. Write tasks so they are safe to run multiple times.

### 3. Connect Terraform to Ansible

Use a `null_resource` only after the EC2 instance exists. Reference the EC2 instance's public IP address directly and use `triggers` to rerun the configuration only when a meaningful input changes.

The local-exec command runs on the Terraform control machine. A typical command supplies the target address, the private-key path, remote user, and playbook name to Ansible:

```text
ansible-playbook -i <ec2-public-ip>, --private-key <path-to-private-key> --user ec2-user playbook.yaml
```

The comma after the IP address is required when a single host is used as inline inventory. Without it, Ansible may interpret the address as an inventory-file name.

### 4. Test before applying infrastructure changes

Validate both Terraform and Ansible before provisioning:

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan
ansible-playbook --syntax-check playbook.yaml
```

Review the Terraform plan carefully. It can create, modify, or destroy actual AWS resources.

### 5. Apply and configure the server

After the plan is approved, apply the Terraform configuration:

```bash
terraform apply
```

Terraform creates the EC2 instance and then the local-exec provisioner invokes Ansible. The EC2 instance must be fully booted and accepting SSH connections before Ansible starts. Add retry or wait logic in the playbook when a new instance may not be immediately ready.

### 6. Reconfigure safely

Terraform provisioners do not automatically run on every `terraform apply`. Define clear `triggers` in the `null_resource`, for example an EC2 instance ID or a hash of the playbook, when the configuration should rerun.

For routine server configuration updates, running Ansible directly from a CI/CD pipeline is often easier to observe, retry, and control than forcing Terraform resource replacement or manipulating provisioner triggers.

## Verification

After a successful apply, verify that Terraform created the expected infrastructure and that Ansible completed all tasks:

```bash
terraform output ec2_public_ip
ansible -i <ec2-public-ip>, --private-key <path-to-private-key> --user ec2-user all -m ping
```

Connect to the instance and verify the configured services and users. For a Docker installation, for example:

```bash
ssh -i <path-to-private-key> ec2-user@<ec2-public-ip>
docker --version
sudo systemctl status docker
```

Read the Terraform output and Ansible task recap. A successful playbook shows `failed=0` for each managed host.

## Before You Run

Complete the following corrections in the current files before running this project:

- [ ] Add tasks to `playbook.yaml`; it is currently empty.
- [ ] Update `working_dir` to this project's actual directory. The current path points to the separate `Complete_CI_CD_with_Terraform` project and starts with `/User/` instead of the usual macOS `/Users/` path.
- [ ] Change `-inventroy` to `-i` or `--inventory` in the Ansible command.
- [ ] Reference the real playbook filename, `playbook.yaml`; `deployment_docker-new-user.yaml` does not exist in this project.
- [ ] Replace `self.public_ip` in the `null_resource`. A `null_resource` has no public IP address; reference the EC2 resource, such as `aws_instance.myapp_server.public_ip`.
- [ ] Add a complete `aws_instance` resource and the provider, variables, VPC, subnet, and security-group definitions that it needs.
- [ ] Add a `depends_on` reference so the configuration starts only after the EC2 instance is created.
- [ ] Add `triggers` so Terraform knows when Ansible configuration should rerun.
- [ ] Ensure the EC2 security group permits SSH from the Ansible control node, not from the entire internet.
- [ ] Verify the operating system and `--user` value match the AMI. `ec2-user` is common for Amazon Linux but not for Ubuntu.
- [ ] Keep the SSH private key outside the repository and restrict its local file permissions.

## Security and Operations Guidance

- Use separate AWS environments and Terraform state files for development, testing, and production.
- Store Terraform state remotely with encryption, versioning, and locking when more than one person or pipeline works on the project.
- Use least-privilege IAM roles and short-lived credentials where possible.
- Restrict SSH with security groups and verify host keys rather than disabling SSH host-key checking.
- Use Ansible Vault or a CI/CD secret store for encrypted Ansible variables.
- Keep playbooks idempotent so repeated runs converge safely on the intended configuration.
- Record Terraform and Ansible output in CI/CD logs and add monitoring and health checks for deployed services.
- Use a protected CI/CD pipeline with approvals for production Terraform applies.
- Destroy unused learning infrastructure to avoid unexpected AWS charges.

## Resources

- [Terraform provisioners documentation](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax)
- [Terraform `null_resource` documentation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)
- [Ansible playbook guide](https://docs.ansible.com/ansible/latest/playbook_guide/)
- [Ansible inventory documentation](https://docs.ansible.com/ansible/latest/inventory_guide/)
- [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 documentation](https://docs.aws.amazon.com/ec2/)

## Topics to Add Later

- A complete, idempotent Docker-host configuration in `playbook.yaml`
- A full Terraform VPC, subnet, security-group, and EC2 configuration
- Dynamic Ansible inventory for multiple EC2 instances
- Cloud-init or Packer images as alternatives for initial server bootstrapping
- CI/CD integration for reviewed Terraform plans and controlled Ansible runs
- Application deployment, health checks, monitoring, and rollback steps