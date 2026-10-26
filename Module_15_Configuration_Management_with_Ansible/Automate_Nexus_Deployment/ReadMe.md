# Demo Project: Automate Nexus Repository Deployment

## Overview

This project uses Ansible to install, configure, and verify **Sonatype Nexus Repository** on an Ubuntu or Debian server. Nexus is an artifact repository manager used to store and distribute build artifacts, container images, and dependencies.

The goal is to make the server configuration repeatable. Instead of manually installing Java, creating users, downloading Nexus, and starting services, an Ansible playbook should converge a new Droplet on the same desired state every time it runs.

> **Current repository status:** The project contains an executable development baseline: `deploy-nexus.yaml`, a safe example inventory, shared variables, and a `systemd` template. It is intentionally junior-friendly; inline `TODO` comments identify the next practical improvements.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| DigitalOcean | Hosts the Linux Droplet that runs Nexus. |
| Linux | Operating system for the Nexus server. |
| Ansible | Automates host configuration and Nexus deployment. |
| Java | Required runtime for Nexus Repository. |
| Sonatype Nexus Repository | Artifact and package repository manager. |

## What the Automation Should Do

The Ansible automation should:

1. Create or use a DigitalOcean Droplet with a supported Linux distribution.
2. Connect securely to the Droplet using a non-root automation user.
3. Install required operating-system packages and a supported Java runtime.
4. Create a dedicated, non-login `nexus` service account and required directories.
5. Download a **pinned** Nexus version and verify its published checksum.
6. Configure Nexus as a managed `systemd` service.
7. Start and enable the service so it returns after a reboot.
8. Wait for the Nexus health endpoint and fail the deployment if Nexus does not become ready.

## What the Current Playbook Does

`deploy-nexus.yaml` targets the `nexus_servers` inventory group and:

1. Validates that the server is Debian-based.
2. Installs the configured Java runtime and `tar`.
3. Creates a non-login `nexus` service account.
4. Downloads a pinned Nexus archive and extracts it below `/opt`.
5. Creates `/opt/nexus` as a stable link to the versioned installation.
6. Configures Nexus to run as the `nexus` user.
7. Installs and enables a `systemd` service.
8. Optionally checks the Nexus status endpoint after startup.

| Current file | Purpose |
| --- | --- |
| `deploy-nexus.yaml` | Main Ansible deployment playbook. |
| `hosts` | Safe example inventory using a documentation-only address. |
| `group_vars/nexus_servers.yaml` | Non-secret Nexus version, path, Java, and health-check settings. |
| `templates/nexus.service.j2` | `systemd` service template that runs Nexus as `nexus`. |
| `ansible.cfg` | Uses the example inventory and keeps SSH host-key checking enabled. |
| `draft.yaml` | Historical notes only; it is not an executable playbook. |

## Architecture

```text
Developer workstation or CI/CD runner
	|
	| Ansible over SSH (or a private network/VPN)
	v
DigitalOcean Droplet
├── Linux packages and supported Java runtime
├── nexus service account
├── /opt/nexus                 # Nexus application installation
├── /opt/sonatype-work         # Nexus data directory
└── systemd → nexus.service → Nexus Repository (default port 8081)
```

For a real environment, place the Droplet behind private networking or a reverse proxy/load balancer with TLS. Do not expose the Nexus administrative interface broadly to the internet.

## Suggested Repository Structure

As the project grows, move the current playbook tasks into a reusable Ansible role:

```text
Automate_Nexus_Deployment/
├── ReadMe.md
├── ansible.cfg
├── inventory/
│   ├── development.ini
│   └── production.ini
├── group_vars/
│   └── nexus_servers.yaml
├── deploy-nexus.yaml
├── requirements.yml
└── roles/
    └── nexus/
	├── defaults/main.yaml
	├── tasks/main.yaml
	├── handlers/main.yaml
	├── templates/nexus.service.j2
	└── vars/main.yaml
```

Keep credentials in an Ansible Vault file or an approved external secret manager. Do not add private SSH keys, DigitalOcean API tokens, Nexus administrator passwords, or real inventory addresses to Git.

## Prerequisites

Before implementing or running the playbook, make sure you have:

- A DigitalOcean account and a project with permission to create/manage a Droplet.
- A supported Linux Droplet, preferably Ubuntu LTS or another distribution verified by the playbook.
- A DigitalOcean firewall that permits SSH only from trusted automation addresses and Nexus access only from intended users or a reverse proxy.
- An SSH key registered with DigitalOcean and an automation account with `sudo` privileges.
- Ansible installed on the control node or CI/CD runner.
- A Java version supported by the selected Nexus Repository release.
- Network egress from the server to the trusted Nexus download source, or an internal artifact mirror.

Verify local tooling before deployment:

```bash
ansible --version
ansible-galaxy collection list
```

## Implementation Steps

### 1. Create and secure the DigitalOcean server

Create a Droplet in the required region and attach only the networking it needs. Use a documented size appropriate for expected repository storage, memory, and concurrent users.

Security baseline:

- Use an SSH key; do not enable password-based SSH authentication.
- Create a dedicated automation user rather than routinely logging in as `root`.
- Restrict port `22` to the CI/CD runner, VPN, or administrator IP range.
- Restrict Nexus port `8081`; in production it should normally be private or exposed only through an HTTPS reverse proxy.
- Enable monitoring, backups/snapshots, and alerting for disk usage. Artifact repositories consume storage quickly.

### 2. Define inventory and connection settings

Put the server in a clearly named group such as `nexus_servers`. Define the remote user, SSH key or certificate, and privilege escalation outside the playbook where possible.

The committed `hosts` file already uses this safe inventory shape. Replace the documentation address only in your local development copy:

```ini
[nexus_servers]
nexus-01 ansible_host=203.0.113.10 ansible_user=automation
```

Keep SSH host-key checking enabled. For production, use a trusted `known_hosts` file, SSH certificates, or a private connection path rather than disabling verification.

### 3. Parameterise the Nexus deployment

Put non-secret settings in role defaults or `group_vars`, for example:

- `nexus_version`
- `nexus_download_url`
- `nexus_checksum`
- `nexus_user` and `nexus_group`
- `nexus_install_dir`
- `nexus_data_dir`
- `nexus_port`
- `nexus_java_package`

The current playbook pins `nexus_version` and derives the download URL from it. `nexus_checksum` is deliberately blank for the learning baseline. Before deploying outside a disposable environment, set it to the vendor-published value in `sha256:<digest>` format so Ansible verifies the downloaded archive. Avoid `latest`: it makes rollbacks and incident investigation difficult.

### 4. Build an idempotent Nexus role

The Nexus role should use modules such as `package`, `user`, `group`, `file`, `get_url`, `unarchive`, `template`, and `systemd` rather than shell commands where a module is available.

Important role responsibilities:

1. Install Java and OS dependencies.
2. Create the `nexus` group and non-login service user.
3. Create installation and data directories with correct ownership.
4. Download and unpack the versioned Nexus archive.
5. Render a `nexus.service` systemd unit from a template.
6. Notify a handler to reload systemd or restart Nexus only when configuration changes.
7. Enable and start the service.

The service must run as the dedicated `nexus` user, not as root. Keep Nexus data on a persistent volume/disk with a backup plan.

### 5. Verify the application

Use Ansible's `uri` module with retries and a delay to wait for the service to become available. A useful initial check is the Nexus status endpoint:

```text
http://<nexus-host>:8081/service/rest/v1/status
```

The verification task should fail clearly if it does not receive the expected HTTP response before the retry limit is reached. Also validate that `nexus.service` is enabled and active through the `systemd` module.

### 6. Run safely

Validate before changing a server:

```bash
ansible-playbook --syntax-check -i hosts deploy-nexus.yaml
ansible-playbook --list-tasks -i hosts deploy-nexus.yaml
ansible-playbook --check --diff -i hosts deploy-nexus.yaml
```

After reviewing check-mode output, deploy to development first:

```bash
ansible-playbook -i hosts deploy-nexus.yaml
```

Promote the same pinned version and reviewed playbook through staging and production. For multiple Nexus nodes, use `serial` deployment and define a tested rollback procedure.

## Verification

After a successful deployment, verify:

```bash
systemctl is-enabled nexus
systemctl is-active nexus
curl --fail http://localhost:8081/service/rest/v1/status
```

Expected results:

- The `nexus` service is **enabled** and **active**.
- Nexus responds on the configured port.
- Nexus files and data directories are owned by the dedicated service account.
- The service starts successfully after a controlled host reboot.
- Logs show no Java, permission, or storage errors.

Useful troubleshooting locations are the systemd journal and the Nexus log directory under the configured data path. Never include passwords, API tokens, or private repository URLs in logs committed to the repository.

## Production Hardening Checklist

- [ ] Use private networking or a reverse proxy with TLS; do not expose port `8081` openly.
- [ ] Restrict SSH and Nexus access with DigitalOcean Cloud Firewalls.
- [ ] Use a non-root automation user and a non-login `nexus` service user.
- [ ] Pin Nexus and Java versions, and verify download checksums.
- [ ] Store all secrets in Ansible Vault or an external secret manager.
- [ ] Enable DigitalOcean backups/snapshots and test data restoration.
- [ ] Monitor disk capacity, JVM health, service availability, and backup failures.
- [ ] Configure log rotation and retain logs according to the environment's policy.
- [ ] Add `ansible-lint`, syntax checks, check mode, and Molecule tests to CI/CD.
- [ ] Document an upgrade, rollback, and disaster-recovery procedure.

## Good Next Steps

The `TODO` comments in the playbook and service template are practical next tasks for a junior DevOps portfolio project:

1. Add the vendor-published SHA-256 value to `nexus_checksum`.
2. Confirm the Java release supported by the pinned Nexus version before upgrading either dependency.
3. Test the status endpoint, then set `nexus_healthcheck_enabled: true`.
4. Add Nginx or Caddy with HTTPS and keep port `8081` private when possible.
5. Use Ansible Vault or a secret manager for administrator credentials and integration tokens.
6. Back up `sonatype-work`, restore it in a test environment, and document the result.
7. Monitor disk capacity, JVM memory, process availability, and failed backup jobs.
8. Add `ansible-lint`, syntax checking, and a disposable test Droplet in CI/CD.

## Resources

- [Ansible Playbook Guide](https://docs.ansible.com/ansible/latest/playbook_guide/index.html)
- [Ansible `systemd` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_service_module.html)
- [Ansible `uri` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
- [Sonatype Nexus Repository documentation](https://help.sonatype.com/en/nexus-repository.html)
- [DigitalOcean Cloud Firewalls documentation](https://docs.digitalocean.com/products/networking/firewalls/)