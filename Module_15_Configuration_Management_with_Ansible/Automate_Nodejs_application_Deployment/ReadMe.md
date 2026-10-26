# Demo Project: Automate Node.js Application Deployment

## Overview

This project uses Ansible to prepare an Ubuntu/Debian server and deploy a Node.js application from a local `.tgz` archive. The playbook installs Node.js and npm, creates a dedicated service account, installs application dependencies, and runs the application with `systemd`.

It is intentionally a **junior-friendly learning project**: the workflow is usable for a development Droplet, while inline `TODO` comments show the next improvements to make as the project grows.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Ansible | Configures the server and deploys the application. |
| Node.js and npm | Runs the application and installs its dependencies. |
| Linux (Ubuntu/Debian) | Supported target operating system for the current playbook. |
| systemd | Starts the application and restarts it when the process fails. |
| DigitalOcean | Example cloud provider for the target server. |

## What the Playbook Does

`deploy-node.yaml` targets the `node_app_servers` inventory group and:

1. Confirms the host is Debian-based.
2. Updates the apt cache and installs `nodejs` and `npm`.
3. Creates the non-login `nodeapp` service account.
4. Creates application directories below `/opt/my-node-app/`.
5. Copies and extracts a versioned Node.js application archive.
6. Installs production npm dependencies.
7. Creates a `current` symlink to the deployed release.
8. Installs a `systemd` service and ensures it is enabled and started.
9. Optionally calls an HTTP health endpoint after deployment.

The default release layout is:

```text
/opt/my-node-app/
├── current -> releases/1.0.0
└── releases/
    └── 1.0.0/
        ├── package.json
        ├── package-lock.json
        └── server.js
```

## Project Files

| File | Purpose |
| --- | --- |
| `deploy-node.yaml` | Main deployment playbook. |
| `inventory.example.ini` | Safe example inventory; replace its documentation IP locally. |
| `group_vars/node_app_servers.yaml` | Non-secret settings: application name, release version, port, and paths. |
| `templates/my-node-app.service.j2` | `systemd` service template for running Node.js as `nodeapp`. |
| `ansible.cfg` | Uses the example inventory and enables SSH host-key checking. |
| `files/my-node-app-1.0.0.tgz` | **You must add this archive** before running the playbook. It is not committed. |

## Prerequisites

You need:

- An Ubuntu or Debian server, such as a development DigitalOcean Droplet.
- A non-root SSH automation user with `sudo` permissions.
- SSH key authentication and an SSH firewall rule restricted to your trusted IP, VPN, or CI/CD runner.
- Ansible installed on the control machine.
- The `community.general` collection for the npm module.
- A Node.js application archive containing `package.json` and the configured entry point (`server.js` by default).

Install the required collection:

```bash
ansible-galaxy collection install community.general
```

## Prepare the Application Archive

Build or package the application on the control machine. The archive must expand into an application directory with `package.json` and `server.js` at its root.

For the current default variables, create this local file:

```text
files/my-node-app-1.0.0.tgz
```

The archive should contain:

```text
package.json
package-lock.json
server.js
```

Do not include `node_modules`, `.env`, API tokens, or credentials in the archive.

## Configure the Inventory

Copy the example inventory for your local use and replace the documentation address:

```ini
[node_app_servers]
node-app-01 ansible_host=<your-droplet-ip> ansible_user=automation
```

Do not commit production IP addresses, passwords, or private-key paths. Keep host-key checking enabled.

## Configure the Deployment

Review `group_vars/node_app_servers.yaml` before deploying:

- Change `app_release_version` whenever you deploy a new archive.
- Change `app_entrypoint` if your application starts from another file.
- Set `app_port` to the port used by your application.
- Keep `app_healthcheck_enabled: false` until the application has a real endpoint such as `/healthz` that returns HTTP 200.

The current application user is a non-login service account. It owns application files but cannot be used for normal SSH administration.

## Run the Playbook

First, validate its structure without changing the server:

```bash
ansible-playbook --syntax-check -i inventory.example.ini deploy-node.yaml
ansible-playbook --list-tasks -i inventory.example.ini deploy-node.yaml
```

After replacing the inventory host and adding the archive, deploy:

```bash
ansible-playbook -i inventory.example.ini deploy-node.yaml
```

## Verification

On the managed server, verify the service:

```bash
sudo systemctl status my-node-app
sudo journalctl -u my-node-app --no-pager
```

If health checks are enabled, validate the same endpoint locally:

```bash
curl --fail http://127.0.0.1:3000/healthz
```

Expected results:

- Node.js and npm are installed.
- The `nodeapp` account owns the application release directory.
- `my-node-app.service` is enabled and active.
- The Node.js process restarts through `systemd` if it exits unexpectedly.

## Good Next Steps

The `TODO` comments in the playbook and service template are realistic next tasks for a junior DevOps portfolio project:

1. **Pin Node.js:** install a tested Node.js LTS version instead of relying on the apt repository version.
2. **Add a health endpoint:** implement `/healthz`, set `app_healthcheck_enabled: true`, and verify it after each release.
3. **Use an artifact repository:** download an archive built by CI/CD, then verify its checksum.
4. **Manage secrets safely:** add an `EnvironmentFile` supplied with Ansible Vault or a secret manager; never store secrets in Git.
5. **Add a reverse proxy:** put Nginx or Caddy in front of the Node.js port and enable HTTPS.
6. **Add safer releases:** use `serial: 1`, retain one previous release, and document rollback by repointing `current`.
7. **Test automatically:** add `ansible-lint`, a syntax check, and a disposable test server in CI.

## Security Notes

- Do not deploy or run the application as `root`.
- Do not disable SSH host-key checking or commit SSH private keys.
- Restrict SSH and application traffic with DigitalOcean Cloud Firewalls.
- Keep the Node.js port private when a reverse proxy handles public HTTPS traffic.
- Keep credentials in Ansible Vault or a secret manager, never in `group_vars` committed to Git.

## Resources

- [Ansible Playbook Guide](https://docs.ansible.com/ansible/latest/playbook_guide/index.html)
- [Ansible `systemd_service` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_service_module.html)
- [community.general npm module](https://docs.ansible.com/ansible/latest/collections/community/general/npm_module.html)
- [Node.js releases](https://nodejs.org/en/about/previous-releases)

