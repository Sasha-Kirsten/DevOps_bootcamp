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

> **Current project status:** This project is a presentation-ready development baseline. It includes a validation-first Jenkins Pipeline, explicit EC2 discovery filters, a one-host-at-a-time Docker configuration playbook, and pinned Ansible collection requirements. It has not been run against a real Jenkins control node or EC2 target from this repository.

## How to Present This to Recruiters

Describe the project in outcome-focused terms:

> “I created a Jenkins-driven Ansible workflow that discovers only explicitly tagged development EC2 instances, validates the automation before making changes, and uses a separate Ansible control node to install and enable Docker plus a dedicated deployment user. The pipeline requires an explicit approval parameter before it can modify a host.”

Demonstrate these three pieces in a portfolio walkthrough:

1. **Safety:** show `inventory_aws_ec2.yaml`. Its `Project`, `Environment`, `Role`, and `AnsibleManaged` filters prevent an accidental account-wide rollout.
2. **Repeatability:** show `requirements.yml`, `ansible.cfg`, and the `deploy-docker-new-user.yaml` playbook. Explain that package installation, service enablement, and user creation are idempotent.
3. **Delivery controls:** show `Jenkinsfile`. `APPLY_CHANGES` defaults to `false`, so normal builds perform syntax and inventory validation only; an operator must explicitly opt in before a change is applied.

For screenshots or a short demo video, capture a successful Jenkins validation build, the dynamic inventory graph showing only a disposable development host, and the final `docker --version` / `id linux_user` verification on that host. Redact IP addresses, AWS account IDs, key paths, credentials, and Jenkins secrets.

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
| `Jenkinsfile` | Validation-first Pipeline. It copies project files to the control node, displays the discovered EC2 graph, and applies only when `APPLY_CHANGES=true`. |
| `ansible.cfg` | Enables the AWS EC2 inventory plugin, points to the standard inventory filename, and keeps SSH host-key checking enabled. |
| `inventory_aws_ec2.yaml` | AWS EC2 dynamic inventory source, filtered to explicitly opted-in development Docker hosts. |
| `deploy-docker-new-user.yaml` | Idempotently installs/enables Docker, creates the deployment user, and verifies Docker. |
| `group_vars/all.yaml` | Non-secret default for the deployment username. |
| `requirements.yml` | Pins the required `amazon.aws` Ansible collection. |
| `.gitignore` | Excludes private keys, local inventory overrides, and local host-key files. |
| `Readme.md` | Explains the setup and safe execution of this learning project. |

## What the Current Ansible Files Do

### Dynamic inventory

`inventory_aws_ec2.yaml` uses the `amazon.aws.aws_ec2` inventory plugin to discover only running EC2 instances in `eu-central-1` that carry all of these tags:

```text
Project = jenkins-ansible-demo
Environment = development
Role = docker-host
AnsibleManaged = true
```

The `Role` tag creates the `role_docker_host` Ansible group that the playbook targets. This makes the target selection understandable and auditable in a recruiter demo.

The AWS inventory plugin runs from the **Ansible Control Node**, so that host needs AWS authentication and the Python dependencies required by the plugin.

### Ansible configuration

`ansible.cfg` sets these defaults:

- `inventory = inventory_aws_ec2.yaml`
- `remote_user = ec2-user`
- `enable_plugins = amazon.aws.aws_ec2`
- `host_key_checking = True`

The managed-node private key is intentionally **not** stored in `ansible.cfg`; Jenkins supplies it only when an approved apply job runs.

### Playbook

`deploy-docker-new-user.yaml` targets only `role_docker_host` and performs these actions with elevated privileges:

1. Confirms the host is Red Hat-family Linux.
2. Installs Docker through the OS package manager.
3. Enables and starts Docker so it survives a reboot.
4. Creates `linux_user` and adds it only to the privileged Docker group.
5. Verifies the Docker binary is available.

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

## Required AWS Tags for a Safe Demo

Use one disposable Amazon Linux development instance. Add all four tags before discovering it:

| Key | Required value | Why it matters |
| --- | --- | --- |
| `Project` | `jenkins-ansible-demo` | Limits discovery to this project. |
| `Environment` | `development` | Prevents a development workflow reaching staging/production. |
| `Role` | `docker-host` | Produces the `role_docker_host` group targeted by the playbook. |
| `AnsibleManaged` | `true` | Explicit opt-in before configuration automation can reach the host. |

Never demonstrate this project with `hosts: all` or a discovery configuration that has no filters.

## Local Validation Commands

Run these checks from this directory before committing or configuring Jenkins:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook --syntax-check -i 'localhost,' -c local deploy-docker-new-user.yaml
ansible-playbook --list-tasks -i 'localhost,' -c local deploy-docker-new-user.yaml
ansible-inventory --graph
```

The inventory command may legitimately return an empty `aws_ec2` group when no instances have all required tags. That is a safe outcome. Do not loosen the filters merely to make the graph non-empty.

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

1. Add `ANSIBLE_SERVER_PUBLIC_IP` as a protected Jenkins environment variable or a build parameter. It must identify only the Ansible control node.
2. Create Jenkins SSH private-key credentials named `ansible-server-key` (Jenkins → control node) and `ec2-server-key` (control node → managed nodes). Use the credential IDs in `Jenkinsfile`, or change the Pipeline to match your names.
3. Give the control node an IAM role that can list the required EC2 instances. Keep the role read-only for inventory discovery.
4. Add the required tags to exactly one disposable Amazon Linux host, then run `ansible-inventory --graph` **on the control node** and confirm that it appears only in `role_docker_host`.
5. Create a Jenkins Pipeline job using `Jenkinsfile`. Run it with `APPLY_CHANGES=false` first; the validation and inventory stages should succeed without modifying a host.
6. Review the build log and dynamic inventory output. Only then run a second build with `APPLY_CHANGES=true` to configure the disposable host.
7. Confirm the managed node results: `docker --version`, `systemctl is-enabled docker`, `systemctl is-active docker`, and `id linux_user`.

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