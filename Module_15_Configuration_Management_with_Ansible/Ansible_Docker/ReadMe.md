# Configure a Docker Host with Terraform and Ansible

## Overview

This project shows how Terraform and Ansible can work together to prepare an AWS EC2 instance for containerised applications.

Terraform provisions the EC2 instance and its AWS dependencies. Ansible then connects to the new server, waits for SSH to become available, installs Docker, starts the Docker service, and creates a dedicated Linux user that can use Docker.

The intended next step is to copy a Docker Compose file to the server and start the application containers with Docker Compose.

```text
Terraform provisions AWS EC2
			 │
			 ▼
Ansible waits for SSH access
			 │
			 ▼
Ansible installs and starts Docker
			 │
			 ▼
Ansible creates deployment user
			 │
			 ▼
Docker Compose deploys application containers
```

> **Learning project:** The supplied Terraform and Ansible files are starter examples. Review the **Before You Run** checklist before running them against an AWS account.

## Project Files

| File | Purpose |
| --- | --- |
| `main.tf` | Defines an EC2 instance and attempts to run the Ansible playbook after provisioning. |
| `deploy-docker-new-user.yaml` | Waits for SSH, installs Docker, starts Docker, and creates the `nana` Linux user. |
| `ReadMe.md` | Explains the workflow, prerequisites, verification steps, and improvements needed. |

## What the Current Playbook Does

The Ansible playbook has three plays:

1. **Wait for SSH connection** — checks whether port `22` responds on the new server before continuing.
2. **Install Docker** — uses the `yum` package manager to install Docker and starts the Docker daemon.
3. **Create a Linux user** — creates the user `nana` and adds it to the `adm` and `docker` groups.

The `yum` task indicates that this playbook is intended for an Amazon Linux, Red Hat Enterprise Linux, or compatible EC2 image. Ubuntu uses the `apt` module instead.

## Prerequisites

Before starting, make sure you have:

- An AWS account and an IAM identity with permissions appropriate for the learning environment.
- Terraform installed and authenticated to AWS.
- Ansible installed on the computer or CI/CD runner that will execute the playbook.
- An existing EC2 key pair in the same AWS Region as the instance.
- The matching SSH private-key file stored securely and excluded from Git.
- Network access from the Ansible control machine to the EC2 instance on SSH port `22`.
- An EC2 security group that restricts SSH access to a trusted IP address or network.
- Terraform definitions for the VPC, subnet, security group, and input variables referenced by `main.tf`.
- A Docker Compose file when you are ready to deploy an application.

Verify the command-line tools before proceeding:

```bash
terraform version
ansible --version
```

## Setup Steps

### 1. Prepare the AWS infrastructure configuration

Terraform needs a complete configuration for the EC2 instance and all referenced dependencies. The current `main.tf` expects values and resources such as:

- `var.ami_id`, `var.instance_type`, `var.availability_zone`, and `var.key_name`
- `var.vpc_name` and `var.ssh_key_private`
- `aws_subnet.public`
- `aws_security_group.web_sg`

Define these variables and resources in Terraform files before planning the deployment. The selected AMI must use a `yum`-compatible operating system unless the Ansible playbook is updated for Ubuntu or another distribution.

### 2. Create an Ansible inventory

Ansible needs an inventory that tells it which hosts belong to the `docker_server` group used by the playbook.

For one EC2 instance, an inventory can look like this:

```ini
[docker_server]
<ec2-public-ip> ansible_user=ec2-user ansible_ssh_private_key_file=<path-to-private-key>
```

Replace the placeholders with the actual EC2 public IP address and the local path to your private key. Keep the private key outside the repository and limit its permissions.

### 3. Provision the EC2 instance with Terraform

Run Terraform from the project directory and review every proposed change:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Only run `terraform apply` after reviewing the plan. Terraform will create the EC2 instance; it may take several minutes before the instance accepts SSH connections.

### 4. Run the Ansible playbook

After the instance is available, run the playbook against the `docker_server` inventory group:

```bash
ansible-playbook -i inventory.ini --private-key <path-to-private-key> --user ec2-user deploy-docker-new-user.yaml
```

The first play waits for SSH. The remaining plays run with elevated privileges (`become: yes`) so that Docker can be installed, the service can start, and the Linux user can be created.

### 5. Add Docker Compose deployment

The repository does not currently include a `docker-compose.yaml` file, and the Compose installation task is commented out in the playbook. To deploy an application, add a Compose file and extend the playbook to:

1. Install the Docker Compose plugin or another supported Docker Compose implementation.
2. Create a directory for application files, such as `/opt/myapp`.
3. Copy the Compose file and required configuration files to that directory.
4. Authenticate to a private container registry when required.
5. Pull the application image and start it with `docker compose up -d`.
6. Add a health check to confirm the application is running.

Use versioned container image tags rather than only `latest` so each deployment can be traced and rolled back.

## Verification

After Terraform and Ansible finish, connect to the EC2 instance and verify the configuration:

```bash
ssh -i <path-to-private-key> ec2-user@<ec2-public-ip>
docker --version
sudo systemctl status docker
id nana
```

Expected results:

- Docker is installed and reports a version.
- The Docker service is active and running.
- The `nana` user exists and belongs to the `docker` group.

After adding Docker Compose and an application, also verify:

```bash
docker compose ps
docker ps
docker compose logs --tail=100
```

Check the application endpoint from an allowed network location and review its logs if it does not respond.

## Before You Run

Complete these corrections and checks before executing the current Terraform integration:

- [ ] Correct the Terraform `working_dir` path. The current path begins with `/User/`; macOS normally uses `/Users/`.
- [ ] Correct `-inventroy` to `-i` or `--inventory` in the Ansible command.
- [ ] Use the actual playbook filename, `deploy-docker-new-user.yaml`. The Terraform command refers to `deployment_docker-new-user.yaml`, which does not exist.
- [ ] Provide an inventory containing the `docker_server` group; the playbook's Docker and user-creation plays target this group.
- [ ] Use a trailing comma when passing a single host directly to Ansible, such as `-i <ec2-public-ip>,`, or use an inventory file instead.
- [ ] Fix the `null_resource` provisioner: it uses `self.public_ip`, but a `null_resource` has no public IP address. Pass the EC2 public IP through a trigger or reference `aws_instance.myapp_server.public_ip`.
- [ ] Add the missing Terraform resources, variables, provider configuration, and `server-cmds.sh` file referenced by `main.tf`.
- [ ] Confirm the EC2 AMI uses `yum`; otherwise, replace the Ansible `yum` task with the appropriate package module and package names.
- [ ] Add `enabled: true` to the Docker `systemd` task so Docker starts automatically after a server reboot.
- [ ] Decide whether the `adm` group is required for `nana`; assign only the groups that the deployment user needs.
- [ ] Add a Docker Compose file and uncomment or implement its installation and deployment tasks before expecting application containers to start.
- [ ] Restrict SSH ingress and never commit the SSH private key.

## Security and Operations Guidance

- Use a dedicated deployment user with the minimum permissions needed.
- Membership in the `docker` group is equivalent to high privilege on a host. Grant it only to trusted users and automation identities.
- Prefer AWS IAM roles and short-lived credentials over long-lived AWS access keys.
- Store secrets in an approved secret-management service, not in playbooks, Terraform variables, or Compose files committed to Git.
- Use Ansible Vault or a CI/CD secret store for encrypted Ansible variables.
- Pin container image tags and record the deployed version.
- Keep Docker, the EC2 operating system, and Ansible collections updated.
- Add monitoring, centralised logs, backups, and a documented rollback method before production use.
- Run `terraform destroy` for unused learning infrastructure to prevent unnecessary AWS charges.

## Resources

- [Ansible documentation](https://docs.ansible.com/)
- [Ansible `yum` module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/yum_module.html)
- [Ansible `systemd` module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_module.html)
- [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)

## Topics to Add Later

- A complete Terraform VPC, subnet, and security-group configuration
- A dynamic Ansible inventory that retrieves EC2 hosts from AWS
- A Docker Compose deployment playbook using `community.docker`
- Application health checks and automated rollback
- AWS Systems Manager Session Manager instead of direct SSH access
- CI/CD integration that runs Terraform and Ansible after review and approval