# Integrating Ansible with Jenkins

## Overview

This project demonstrates how Jenkins can run Ansible automation through a dedicated Ansible Control Node. Jenkins securely connects to the control node, copies the required Ansible configuration, and starts a playbook that configures AWS EC2 managed nodes.

The current playbook installs Docker, starts the Docker service, and creates a Linux deployment user on every EC2 instance returned by the Ansible inventory.

```text
Jenkins controller or agent
		  │ SSH
		  ▼
Ansible Control Node
		  │ AWS dynamic inventory + SSH
		  ▼
AWS EC2 managed nodes
		  │
		  ▼
Docker installed and deployment user created
```

> **Learning project:** The files in this directory are starter examples. Review the **Before Running the Pipeline** checklist before using them with a real Jenkins server or AWS account.

## Roles in the Architecture

| Component | Responsibility |
| --- | --- |
| Jenkins | Orchestrates the workflow, stores credentials, and records job logs. |
| Ansible Control Node | Runs Ansible, discovers AWS EC2 targets, and connects to the managed nodes. |
| AWS dynamic inventory | Uses the `aws_ec2` inventory plugin to find EC2 instances in the configured AWS Region. |
| EC2 managed nodes | The servers configured by the Ansible playbook. |
| Jenkins credentials | Securely provide SSH private keys and, where needed, AWS authentication. |

## Project Files

| File | Purpose |
| --- | --- |
| `jenkinsfile` | Jenkins Pipeline definition that copies files to the control node and runs remote Ansible commands. Jenkins conventionally expects `Jenkinsfile`. |
| `ansible.cfg` | Sets Ansible defaults including the inventory path, remote user, SSH key path, and AWS dynamic inventory plugin. |
| `inventroy_aws_ec2.yaml` | AWS EC2 dynamic inventory source. The filename contains a typo and should be renamed for consistency. |
| `deploy-docker-new-user.yaml` | Playbook that installs Docker, starts Docker, and creates `linux_user`. |
| `Readme.md` | Explains the setup and safe execution of this learning project. |

## What the Current Ansible Files Do

### Dynamic inventory

`inventroy_aws_ec2.yaml` uses the `aws_ec2` inventory plugin to discover instances in `eu-central-1`. It creates groups based on EC2 tags and instance types. For example, instances with an `Environment=dev` tag can be selected through a generated tag-based group after the inventory configuration is refined.

The AWS inventory plugin runs from the **Ansible Control Node**, so that host needs AWS authentication and the Python dependencies required by the plugin.

### Ansible configuration

`ansible.cfg` sets these defaults:

- `inventory = inventory_aws_ec2.yml`
- `remote_user = ec2-user`
- `private_key_file = ~/.ssh/id_rsa`
- `enable_plugins = aws_ec2`

Host-key checking is currently disabled. This is convenient for a short-lived lab but is not recommended for a production environment because it removes SSH server identity verification.

### Playbook

`deploy-docker-new-user.yaml` targets all discovered hosts and performs these actions with elevated privileges:

1. Installs Docker with the Ansible `yum` module.
2. Starts the Docker daemon with the `systemd` module.
3. Creates the `linux_user` account and adds it to the `adm` and `docker` groups.

Because the playbook uses `yum`, the managed EC2 instances must use Amazon Linux, RHEL, or a compatible operating system. Ubuntu systems require the Ansible `apt` module and Ubuntu package names instead.

## Prerequisites

Prepare the following components before creating the Jenkins job:

- A Jenkins controller or agent that can reach the Ansible Control Node by SSH.
- A dedicated Ansible Control Node with Ansible, Python 3, AWS CLI tools, and the Amazon AWS Ansible collection installed.
- An AWS account with EC2 instances in the selected Region and an IAM role or credentials that allow inventory discovery.
- EC2 managed nodes that allow SSH only from the Ansible Control Node or a controlled private network.
- A compatible AMI and the correct remote username, such as `ec2-user` for Amazon Linux.
- Two separate SSH credentials: one for Jenkins to access the control node, and one for the control node to access managed nodes.
- Jenkins Pipeline, SSH Agent, Credentials Binding, and SSH Steps plugins or equivalent agent capabilities.
- A clear tagging convention to select only the intended EC2 managed nodes.

Use IAM roles and short-lived credentials where possible. Do not commit private SSH keys, AWS access keys, or passwords to Git.

## Setup Steps

### 1. Prepare the Ansible Control Node

The control node must be ready to run the AWS dynamic inventory plugin and connect to managed nodes. Install Ansible, Python 3, `boto3`, `botocore`, and the `amazon.aws` collection. The exact installation method depends on the operating system and Ansible version.

Verify the setup on the control node:

```bash
ansible --version
ansible-galaxy collection list amazon.aws
python3 -c "import boto3; print(boto3.__version__)"
```

Configure AWS authentication on the control node through an attached IAM role, an AWS profile, or an approved secret-management mechanism. The identity needs permission to describe only the EC2 instances that the inventory must discover.

### 2. Prepare SSH access and Jenkins credentials

Create separate Jenkins credentials for the two SSH hops:

| Credential ID | Purpose |
| --- | --- |
| `ansible-server-key` | Lets Jenkins copy files to and connect to the Ansible Control Node. |
| `ec2-server-key` | Lets the Ansible Control Node connect to the managed EC2 instances. |

Store both as Jenkins SSH private-key credentials. Configure the EC2 security groups so Jenkins can reach only the control node, and the control node can reach only the managed nodes over port `22`.

### 3. Configure the AWS dynamic inventory

Set the inventory plugin Region and filters so that it returns only the intended managed nodes. Test inventory discovery directly on the control node before running the Jenkins job:

```bash
ansible-inventory -i inventory_aws_ec2.yaml --graph
ansible-inventory -i inventory_aws_ec2.yaml --list
```

Use filters or tag-based groups to avoid accidentally configuring every EC2 instance in the AWS account or Region. For example, target instances tagged for this automation project and environment.

### 4. Configure `ansible.cfg`

The configuration file centralises default values for inventory, SSH user, SSH key location, and enabled inventory plugins. Store the managed-node SSH private key on the control node with restrictive permissions, such as `chmod 600`.

For production, enable host-key checking and manage trusted host fingerprints in a `known_hosts` file. Do not use `host_key_checking = False` outside a controlled lab.

### 5. Build the Jenkins pipeline

The intended Jenkins workflow has two stages:

1. **Copy files to the Ansible Control Node** — copy `ansible.cfg`, the AWS inventory source, and the playbook to a deployment directory on the control node. Provide the managed-node SSH key securely without saving it in the Git repository.
2. **Execute the Ansible playbook** — connect to the control node and execute an inventory check followed by the configuration playbook.

The pipeline should fail immediately if a copy, inventory, connection, or playbook task fails. Record the Ansible output in Jenkins logs and use a controlled working directory on the remote control node.

### 6. Run and verify the playbook

Before making changes, run a connectivity test against only the selected group:

```bash
ansible-inventory -i inventory_aws_ec2.yaml --graph
ansible <target-group> -i inventory_aws_ec2.yaml -m ping
```

Then apply the configuration:

```bash
ansible-playbook -i inventory_aws_ec2.yaml deploy-docker-new-user.yaml
```

After the job succeeds, connect to a managed node and verify Docker and the deployment user:

```bash
docker --version
sudo systemctl status docker
id linux_user
```

## Before Running the Pipeline

Complete these corrections in the current draft files before executing the automation:

- [ ] Rename `jenkinsfile` to `Jenkinsfile`, or configure Jenkins to use the lowercase filename.
- [ ] Rename `inventroy_aws_ec2.yaml` to `inventory_aws_ec2.yaml`, then update every reference to use the same `.yaml` filename.
- [ ] Update `ansible.cfg`, which currently references `inventory_aws_ec2.yml`; this file does not exist.
- [ ] Copy the individual Ansible files or the correct project directory. The Jenkins pipeline currently copies `ansible/*`, but no `ansible/` directory exists in this project.
- [ ] Create the target directory on the control node before copying files, and run remote Ansible commands from that directory.
- [ ] Fix the remote commands. They currently run `ansible-playbook -i inventory_aws_ec2.yml` without a playbook filename and then reference `playbook.yml`, which does not exist.
- [ ] Run `ansible-inventory -i inventory_aws_ec2.yaml --graph` before the playbook to verify target selection.
- [ ] Define `ANSIBLE_SERVER_PUBLIC_IP` securely as a Jenkins environment variable, parameter, or trusted configuration value.
- [ ] Remove `StrictHostKeyChecking=no` and use managed host keys for non-lab environments.
- [ ] Avoid copying a managed-node private key to `/root/.ssh/` when possible. Use an encrypted secret store, a short-lived key, or AWS Systems Manager Session Manager instead.
- [ ] Align the `remote.user` and `remote.identityFile` values with the control-node credential. The pipeline sets them inconsistently before replacing them with `ec2-server-key` values.
- [ ] Add `enabled: true` to the Docker systemd task so Docker starts after a managed node reboots.
- [ ] Confirm that the `adm` group is necessary for `linux_user`; grant only the permissions required.
- [ ] Add inventory filters and limit the playbook to a dedicated target group rather than `hosts: all`.

## Security and Operations Checklist

- [ ] Separate Jenkins, control-node, and managed-node access using least-privilege credentials.
- [ ] Use IAM roles or short-lived AWS credentials for EC2 inventory discovery.
- [ ] Limit SSH access with security groups, private networking, and trusted host verification.
- [ ] Keep SSH private keys out of Git, Jenkins logs, and long-lived files on the control node.
- [ ] Use Ansible Vault or a CI/CD secret store for encrypted variables.
- [ ] Select managed nodes by dedicated AWS tags and verify the dynamic inventory before every run.
- [ ] Pin and update Ansible collections and Python dependencies.
- [ ] Collect Jenkins and Ansible logs, alert on failures, and document a rollback procedure.
- [ ] Treat Docker-group membership as privileged access and grant it sparingly.

## Resources

- [Ansible documentation](https://docs.ansible.com/)
- [Ansible AWS EC2 dynamic inventory documentation](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html)
- [Ansible playbook guide](https://docs.ansible.com/ansible/latest/playbook_guide/)
- [Jenkins Pipeline documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Jenkins credentials documentation](https://www.jenkins.io/doc/book/using/using-credentials/)
- [AWS EC2 documentation](https://docs.aws.amazon.com/ec2/)

## Topics to Add Later

- A corrected production-ready `Jenkinsfile`
- Inventory filters based on project and environment tags
- An AWS dynamic-inventory IAM policy with least-privilege access
- Docker Compose installation and application deployment tasks
- Application health checks and automated rollback
- AWS Systems Manager Session Manager as an alternative to SSH