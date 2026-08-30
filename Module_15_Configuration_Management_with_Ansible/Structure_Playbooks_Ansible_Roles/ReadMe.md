# Structure Ansible Playbooks with Roles

## Overview

This project demonstrates how to split a large Ansible playbook into smaller, reusable Ansible roles. Roles group related tasks, variables, files, templates, handlers, and defaults into a predictable directory structure.

The project separates two responsibilities:

- **`create_user`** — creates a Linux user and assigns group membership.
- **`start_containers`** — copies a Docker Compose file, authenticates to a container registry, and starts application containers.

```text
Main playbook
	 │
	 ├── Install and start Docker
	 │
	 ├── create_user role
	 │      └── Create deployment user and groups
	 │
	 └── start_containers role
			├── Copy Docker Compose configuration
			├── Authenticate to registry
			└── Start application containers
```

Using roles makes automation easier to read, test, maintain, and reuse across different projects and environments.

> **Learning project:** The role structure is a useful starter, but some values and files are currently placeholders. Complete the **Before You Run** checklist before using the playbook on a real server.

## Why Use Ansible Roles?

A single playbook can become difficult to manage as it grows. Roles solve this by grouping one responsibility in one directory.

Roles provide several benefits:

- Clear separation of responsibilities, such as users, Docker, databases, or monitoring.
- Reusable configuration across multiple playbooks and environments.
- Easier review because tasks and variables are stored near the role that uses them.
- Better testing because each role can be validated independently.
- A consistent structure that helps new team members find files quickly.

## Project Files and Roles

| Path | Purpose |
| --- | --- |
| `deploy-docker-with-roles.yaml` | Main playbook that installs Docker, creates a deployment user, installs Docker Compose, and starts containers. |
| `ansible.cfg` | Intended location for Ansible defaults. It is currently empty. |
| `roles/create_user/defaults/main.yaml` | Default group list for the user-creation role. |
| `roles/create_user/tasks/main.yaml` | Task that creates the Linux user. |
| `roles/start_containers/tasks/main.yaml` | Tasks that copy Compose configuration, log in to Docker, and start services. |
| `roles/start_containers/vars/main.yaml` | Role-specific Docker registry and credential variables. |
| `roles/start_containers/files/docker-compose.yaml` | Intended Docker Compose file copied by the role. It is currently empty. |

## Standard Role Structure

Ansible recognises conventional directories within a role:

```text
roles/
├── create_user/
│   ├── defaults/
│   │   └── main.yaml
│   └── tasks/
│       └── main.yaml
└── start_containers/
	├── files/
	│   └── docker-compose.yaml
	├── tasks/
	│   └── main.yaml
	└── vars/
		└── main.yaml
```

Common role directories include:

| Directory | Use |
| --- | --- |
| `tasks/` | The role's main automation tasks. Ansible begins with `tasks/main.yaml`. |
| `defaults/` | Variables with low priority that users of the role can safely override. |
| `vars/` | Role variables with higher priority. Do not store secrets here in plain text. |
| `files/` | Static files copied directly to managed hosts. |
| `templates/` | Jinja2 template files rendered with variables before being copied. |
| `handlers/` | Tasks triggered only when notified, typically for service restarts. |
| `meta/` | Role metadata and declared dependencies on other roles or collections. |

## What the Current Roles Do

### `create_user`

The `create_user` role has a default `groups` variable with the value `admin, docker`. Its task creates the user `aleksanderkirsten` and assigns that user to the configured groups.

The main playbook calls this role with a `user_groups` variable, but the role reads `groups` instead. This mismatch must be corrected before the group override will work.

> **Security note:** Docker-group membership grants high privilege on a Linux host. Give it only to trusted deployment users and automation identities.

### `start_containers`

The `start_containers` role is intended to:

1. Copy a Docker Compose file to `/home/aleksanderkirsten/docker-compose.yaml`.
2. Authenticate to Docker Hub or another container registry.
3. Run `community.docker.docker_compose_v2` from `/home/aleksanderkirsten` to start the services.

This role needs a real Compose file and secure credentials before it can be used. It should copy the file included in the role rather than a fixed path from one developer's macOS machine.

## Prerequisites

Before running this project, make sure you have:

- Ansible installed on the control node or CI/CD runner.
- SSH network access and valid credentials for the managed hosts.
- A supported Linux operating system on the managed hosts.
- Docker installed, or the required Docker installation tasks enabled in the main playbook.
- Docker Compose v2 installed on hosts that will run `community.docker.docker_compose_v2`.
- The `community.docker` Ansible collection installed on the control node.
- A completed `docker-compose.yaml` file and application images available in a container registry.
- Registry credentials stored securely with Ansible Vault or a CI/CD secret store.

Verify the required tooling:

```bash
ansible --version
ansible-galaxy collection list community.docker
```

## Implementation Steps

### 1. Identify responsibilities in the original playbook

Break large playbooks into independent concerns. In this project, the main concerns are:

1. Installing and starting Docker.
2. Creating a deployment user.
3. Installing Docker Compose.
4. Copying application configuration.
5. Authenticating to the image registry.
6. Starting application containers.

Each concern can become a role when it is likely to be reused, changed separately, or tested independently.

### 2. Keep the main playbook small

The main playbook should describe **which roles** apply to a host. Detailed implementation belongs in the role task files.

A clean final structure can apply roles in this order:

1. A Docker installation role ensures Docker is installed, enabled, and running.
2. The `create_user` role creates the deployment user.
3. A Docker Compose role installs the Compose plugin.
4. The `start_containers` role copies configuration and starts the application.

This makes the execution order clear without placing every task in one large file.

### 3. Use role defaults for configurable values

Define values that users may override in `defaults/main.yaml`. Typical values include:

- `deployment_user`
- `deployment_groups`
- `application_directory`
- `compose_filename`
- `docker_registry`
- `docker_image_tag`

Pass environment-specific values from inventory group variables, `vars_files`, extra variables, or the CI/CD pipeline. Avoid hard-coding usernames, paths, image tags, or environment names inside tasks.

### 4. Keep secrets out of role variables

The current `start_containers/vars/main.yaml` contains a placeholder Docker password. Do not replace it with a real password in Git.

Use Ansible Vault or an external secret store instead. For example, encrypt a separate variables file, then provide it to the playbook at runtime. Ensure CI/CD logs do not print registry passwords or authentication tokens.

### 5. Copy the Compose file from the role

Place the completed `docker-compose.yaml` inside `roles/start_containers/files/`. The copy task should refer to the role file by its relative name, allowing Ansible to locate it automatically.

The destination directory must exist and be owned by the deployment user. Start services from the same directory so Docker Compose can read the configuration and any related environment files.

### 6. Run and validate the playbook

Check the playbook before changing a managed host:

```bash
ansible-playbook --syntax-check deploy-docker-with-roles.yaml
ansible-playbook --list-tasks deploy-docker-with-roles.yaml
ansible-playbook --check deploy-docker-with-roles.yaml
```

After reviewing the check-mode output, apply the configuration:

```bash
ansible-playbook deploy-docker-with-roles.yaml
```

Use an explicit inventory with the command, or configure a default inventory in `ansible.cfg`.

## Verification

After a successful playbook run, verify the desired host state:

```bash
docker --version
docker compose version
sudo systemctl status docker
id aleksanderkirsten
docker compose -f /home/aleksanderkirsten/docker-compose.yaml ps
```

Expected results:

- Docker and Docker Compose are installed.
- Docker is running and enabled after a host reboot.
- The deployment user exists and has only the required group memberships.
- The Compose file is present in the application directory.
- The expected application containers are running and healthy.

Review `docker compose logs` and any application health endpoint if a container does not start as expected.

## Before You Run

Complete these corrections in the current files before running this project:

- [ ] Add an inventory and connection defaults to the empty `ansible.cfg`, or pass an inventory explicitly with `-i`.
- [ ] Rename the role variable consistently. The main playbook sets `user_groups`, while `create_user` reads `groups`.
- [ ] Replace the hard-coded `aleksanderkirsten` username with a configurable variable, such as `deployment_user`.
- [ ] Confirm whether `admin` is a valid group for the selected Linux distribution; use only necessary groups.
- [ ] Add `enabled: true` to the Docker `systemd` task so Docker starts after reboots.
- [ ] Complete the Docker Compose installation URL based on the target operating system and detected architecture.
- [ ] Create the completed `roles/start_containers/files/docker-compose.yaml`; it is currently empty.
- [ ] Change the Compose copy task to use the role's bundled file, not the machine-specific `/Users/aleksanderkirsten/Bootcamp/docker-compose.yaml` path.
- [ ] Ensure `/home/<deployment-user>` or the chosen application directory exists and has correct ownership before copying files.
- [ ] Replace the placeholder Docker password with an Ansible Vault variable or external secret-store value.
- [ ] Use the `docker_registry` and `docker_username` variables consistently in the `docker_login` task instead of hard-coded values.
- [ ] Add the `start_containers` role to the main playbook's `roles:` list; it currently is not invoked as a role.
- [ ] Add container health checks, image version variables, and a rollback strategy before production use.

## Security and Operations Guidance

- Store secrets in Ansible Vault or an approved external secret store, never in role files committed to Git.
- Treat Docker-group membership as privileged access.
- Use immutable, versioned container image tags rather than only `latest`.
- Pin Ansible collection versions and update them deliberately.
- Keep all tasks idempotent so repeated playbook runs safely converge on the desired state.
- Use `handlers` to restart services only when their configuration actually changes.
- Test roles independently in a disposable development environment before shared or production hosts.
- Collect deployment logs, monitor container health, and retain a documented rollback procedure.

## Resources

- [Ansible roles documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
- [Ansible best practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [Ansible `user` module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html)
- [Ansible `copy` module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)
- [Community Docker collection documentation](https://docs.ansible.com/ansible/latest/collections/community/docker/)
- [Docker Compose documentation](https://docs.docker.com/compose/)

## Topics to Add Later

- A separate reusable role for installing Docker and Docker Compose
- Role variables for different environments and operating systems
- An Ansible Vault example for registry credentials
- A complete Docker Compose application deployment example
- Molecule tests for the `create_user` and `start_containers` roles
- CI/CD checks for Ansible syntax, linting, and test deployments