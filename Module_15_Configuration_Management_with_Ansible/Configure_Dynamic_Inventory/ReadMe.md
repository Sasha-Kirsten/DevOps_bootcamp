# Configure Dynamic Inventory

## Overview

This project demonstrates how to use Ansible's AWS EC2 dynamic inventory instead of maintaining a static list of server IP addresses.

Terraform creates EC2 instances and applies tags to them. The Ansible AWS EC2 inventory plugin queries AWS at runtime, finds instances matching the configured filters, and makes those instances available to Ansible playbooks.

```text
Terraform provisions tagged EC2 instances
									│
									▼
AWS EC2 dynamic inventory queries AWS
									│
									▼
Ansible creates target groups from tags
									│
									▼
Ansible playbook configures matching servers
```

This approach is especially useful when server IP addresses change, instances are added or removed frequently, or separate environments use consistent AWS tags.

> **Learning project:** The supplied Terraform, inventory, and playbook files are starter examples. Review the **Before You Run** checklist before running automation against AWS.

## Project Files

| File | Purpose |
| --- | --- |
| `main.tf` | Defines three EC2 application-server resources and their `Name` tags. |
| `inventory_aws_ec2.yaml` | Uses the Ansible `aws_ec2` dynamic inventory plugin to discover matching EC2 instances. |
| `ansible.cfg` | Contains Ansible defaults, including the current inventory path and SSH private-key location. |
| `hosts` | A static inventory example for manually specified Nexus and Docker servers. |
| `deploy-nexus.yaml` | Starter playbook for installing Nexus prerequisites and Docker. |
| `ReadMe.md` | Explains the dynamic inventory workflow and implementation checks. |

## How Dynamic Inventory Works

The `inventory_aws_ec2.yaml` file is an inventory **source**, not a regular static host list. When Ansible reads it, the `aws_ec2` plugin calls the AWS EC2 API and returns matching instances.

The current inventory source is configured to:

- Search in the AWS Region `eu-central-1`.
- Return only EC2 instances whose `Name` tag begins with `dev`.
- Return only instances in the `running` state.
- Create groups from EC2 tags through `keyed_groups`.

This means a stopped instance or an instance whose `Name` tag does not match `dev*` is intentionally excluded from the dynamic inventory.

## Key Terms

| Term | Meaning |
| --- | --- |
| **Static inventory** | A manually maintained file containing host names or IP addresses, such as `hosts`. |
| **Dynamic inventory** | An inventory source that discovers hosts from an external system at runtime, such as AWS EC2. |
| **Inventory plugin** | Ansible plugin that retrieves hosts and groups. This project uses `amazon.aws.aws_ec2`. |
| **Filter** | A condition that limits which AWS instances appear in the inventory. |
| **Tag** | AWS metadata applied to a resource, often used to identify application, environment, role, or owner. |
| **Host group** | A named selection of target machines used in an Ansible playbook. |

## Prerequisites

Before using this project, make sure you have:

- An AWS account and an IAM role or user with permission to describe the required EC2 instances.
- Terraform installed and authenticated to AWS.
- Ansible installed on the computer or CI/CD runner that will execute the playbook.
- Python 3, `boto3`, and `botocore` installed where Ansible runs.
- The `amazon.aws` Ansible collection installed.
- EC2 instances in `eu-central-1`, or an updated Region in `inventory_aws_ec2.yaml`.
- An EC2 key pair and matching private key for SSH access, stored securely outside Git.
- Security-group rules that allow SSH from the Ansible control machine only.
- A compatible remote user. For example, Amazon Linux often uses `ec2-user`, whereas Ubuntu usually uses `ubuntu`.

Verify the required local tools:

```bash
terraform version
ansible --version
ansible-galaxy collection list amazon.aws
python3 -c "import boto3; print(boto3.__version__)"
```

> **Security note:** Do not commit AWS credentials, SSH private keys, `.pem` files, or sensitive inventory data. Prefer IAM roles or short-lived credentials over long-lived access keys.

## Implementation Steps

### 1. Create consistently tagged EC2 instances with Terraform

Terraform creates three EC2 instances: `myapp_server-one`, `myapp_server-two`, and `myapp_server-three`. Each one receives a `Name` tag composed from `var.vpc_name`.

Use a consistent tag strategy so dynamic inventory can select only the intended targets. For example:

```hcl
tags = {
	Name        = "dev-myapp-server-one"
	Environment = "dev"
	Role        = "docker-server"
	Project     = "myapp"
}
```

The current filter is `tag:Name: dev*`, so `var.vpc_name` must start with `dev` for the Terraform-created instances to appear in the dynamic inventory.

### 2. Validate and apply the Terraform configuration

Run Terraform from the project directory:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Review the plan before applying it. After a successful apply, confirm that the instances are running and their AWS tags match the inventory filter.

### 3. Configure AWS authentication for Ansible

The computer running Ansible needs permission to call the EC2 DescribeInstances API. Configure this through an IAM role, AWS CLI profile, environment variables, or another approved authentication method.

For a learning environment, the required IAM permissions typically include read-only EC2 discovery permissions. Grant only the permissions necessary for the selected account, Region, and resources.

### 4. Test the dynamic inventory

Use the inventory source explicitly to inspect exactly which hosts Ansible discovers:

```bash
ansible-inventory -i inventory_aws_ec2.yaml --graph
ansible-inventory -i inventory_aws_ec2.yaml --list
```

Do this before any playbook run. Check that only the intended EC2 instances appear, that their connection addresses are correct, and that tag-based groups use expected names.

### 5. Test SSH connectivity

After confirming inventory results, test Ansible connectivity against a small, dedicated target group:

```bash
ansible <target-group> -i inventory_aws_ec2.yaml -m ping
```

Replace `<target-group>` with a group generated from your tags or with `all` only for a controlled learning environment. The ping module tests Ansible connectivity; it does not send an ICMP network ping.

### 6. Run the configuration playbook

The starter `deploy-nexus.yaml` contains tasks intended to install Java, `net-tools`, Nexus prerequisites, and Docker. Complete and test those tasks before running it against production hosts.

Run the playbook using the dynamic inventory:

```bash
ansible-playbook -i inventory_aws_ec2.yaml deploy-nexus.yaml
```

Target a dedicated group rather than every discovered host. In the playbook, replace broad `hosts: all` values with a group that represents the intended role, such as a tag-derived Docker or Nexus group.

## Verification

Verify the workflow in this order:

1. **Terraform:** Confirm the EC2 instances exist, are running, and have the required tags.
2. **Inventory:** Run `ansible-inventory -i inventory_aws_ec2.yaml --graph` and confirm only intended hosts are present.
3. **Connectivity:** Run the Ansible ping module against a limited target group.
4. **Playbook:** Review the Ansible task recap; every target should show `failed=0`.
5. **Server state:** Connect to a managed server and confirm installed services and packages.

For Docker-related tasks, verification can include:

```bash
docker --version
sudo systemctl status docker
```

## Before You Run

Complete these corrections and decisions in the current project before using it for a real deployment:

- [ ] Update `ansible.cfg` to use `inventory_aws_ec2.yaml` when dynamic inventory is intended. It currently points to the static `hosts` file.
- [ ] Add `remote_user` to `ansible.cfg` or define it through inventory variables. Confirm it matches the EC2 AMI.
- [ ] Install the `amazon.aws` collection and its `boto3`/`botocore` Python dependencies.
- [ ] Ensure the AWS authentication identity has EC2 read permissions in `eu-central-1`.
- [ ] Confirm the Terraform-created `Name` tags begin with `dev`; otherwise the `tag:Name: dev*` filter excludes every instance.
- [ ] Add additional inventory filters, such as `Environment=dev`, `Project=myapp`, and `Role=docker-server`, to prevent unintended EC2 instances from being managed.
- [ ] Define connection addresses through `hostnames` or `compose` in the dynamic inventory where required. Prefer private IP addresses when the control node is in the same VPC.
- [ ] Add the missing provider, variables, VPC, subnet, security group, and `server-cmds.sh` definitions referenced by `main.tf`.
- [ ] Complete the empty Nexus download URL and destination in `deploy-nexus.yaml` before running it.
- [ ] Choose one compatible operating system per host group. The playbook mixes Ubuntu `apt` tasks and `yum` tasks intended for Amazon Linux/RHEL.
- [ ] Replace `hosts: all` in the playbook with dedicated target groups.
- [ ] Add `enabled: true` to the Docker systemd task so Docker starts after instance reboot.
- [ ] Enable SSH host-key checking and manage trusted host fingerprints for non-lab environments.

## Security and Operations Guidance

- Use AWS tags to isolate environments, applications, and server roles.
- Always inspect dynamic inventory output before applying configuration changes.
- Use least-privilege AWS IAM permissions for inventory discovery.
- Restrict SSH access with security groups and private networking; do not allow SSH from the entire internet.
- Keep SSH keys and AWS credentials out of Git and ordinary Ansible variables.
- Use Ansible Vault or a CI/CD secret store for encrypted variables.
- Keep playbooks idempotent so repeated runs safely converge on the desired state.
- Pin Ansible collections and Python dependencies, then update them deliberately.
- Log inventory and playbook results, monitor managed hosts, and document rollback steps.
- Destroy unused learning EC2 resources to avoid unexpected AWS charges.

## Resources

- [Ansible AWS EC2 dynamic inventory documentation](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html)
- [Ansible inventory documentation](https://docs.ansible.com/ansible/latest/inventory_guide/)
- [Ansible documentation](https://docs.ansible.com/)
- [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 documentation](https://docs.aws.amazon.com/ec2/)

## Topics to Add Later

- A complete Terraform network and variable configuration
- Dynamic-inventory filters for development, test, and production environments
- Tag-derived host groups for Nexus, Docker, and application-server roles
- A complete, operating-system-specific Nexus deployment playbook
- AWS Systems Manager Session Manager as an alternative to SSH
- Jenkins or GitHub Actions integration for reviewed Ansible runs