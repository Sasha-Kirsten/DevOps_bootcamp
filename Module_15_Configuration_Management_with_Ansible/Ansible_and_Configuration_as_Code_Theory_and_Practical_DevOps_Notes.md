# Ansible and Configuration as Code — Theory + Practical DevOps Notes

## Why Configuration as Code matters
Configuration as Code (CaC) means server and platform configuration is versioned, reviewed, and automated like application code.

For DevOps teams, this provides:
- repeatability across environments
- faster and safer changes
- reduced manual drift
- auditable operations
- easier onboarding and incident recovery

Ansible is a common CaC tool because it is agentless, human-readable, and strong for OS/app configuration.

---

## 1) Ansible fundamentals (theory)

### Agentless architecture
Ansible connects over SSH/WinRM from a control node to managed hosts and executes modules remotely.

### Idempotency
Good playbooks are idempotent: multiple runs converge to the same desired state.

### Push model
Ansible usually pushes desired state from control node to targets (unlike pull-based systems).

### YAML + modules
Playbooks are YAML; tasks call modules (e.g., `apt`, `yum`, `service`, `user`, `copy`, `template`).

---

## 2) Core Ansible building blocks

### Inventory
Defines managed hosts/groups.
- static inventory file
- dynamic inventory plugin (e.g., AWS EC2)

### Playbook
Ordered set of plays and tasks targeting inventory groups.

### Roles
Reusable structure for tasks/defaults/templates/handlers/files.

### Variables
Parameterize behavior by environment/team/application.

### Handlers
Run only when notified (e.g., restart service after config change).

### Collections
Versioned package of modules/plugins/roles (e.g., `amazon.aws`, `community.docker`).

---

## 3) Repository structure (recommended)

```text
ansible-project/
├── ansible.cfg
├── inventories/
│   ├── dev/
│   │   ├── hosts.ini
│   │   └── group_vars/
│   ├── staging/
│   └── prod/
├── playbooks/
│   ├── site.yaml
│   ├── docker-host.yaml
│   └── app-deploy.yaml
├── roles/
│   ├── common/
│   ├── docker/
│   └── app/
├── requirements.yml
└── README.md
```

This layout supports scale and environment separation.

---

## 4) Minimal playbook example

```yaml
- name: Configure web host
  hosts: web
  become: true
  tasks:
    - name: Install NGINX
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true

    - name: Ensure NGINX is enabled and running
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

Why this is good:
- declarative states (`present`, `started`, `enabled`)
- idempotent modules
- clear target group (`web`)

---

## 5) Variables and environment separation

### Example variable files
`group_vars/web.yaml`
```yaml
app_user: deploy
app_port: 8080
```

### Use variables in tasks
```yaml
- name: Create app user
  ansible.builtin.user:
    name: "{{ app_user }}"
    shell: /bin/bash
```

Best practice:
- use `defaults` in roles for overridable values
- keep secrets out of plain variable files

---

## 6) Roles for reusable automation

Role skeleton:
```text
roles/myrole/
├── defaults/main.yaml
├── tasks/main.yaml
├── handlers/main.yaml
├── templates/
├── files/
└── meta/main.yaml
```

### Example: role-driven service config
`roles/app/tasks/main.yaml`
```yaml
- name: Copy app config
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/myapp/app.conf
    mode: "0640"
  notify: restart myapp
```

`roles/app/handlers/main.yaml`
```yaml
- name: restart myapp
  ansible.builtin.service:
    name: myapp
    state: restarted
```

---

## 7) Dynamic inventory with AWS (practical)

Example `inventory_aws_ec2.yaml`:
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - eu-central-1
filters:
  instance-state-name: running
  tag:Environment: dev
  tag:Role: docker-host
keyed_groups:
  - key: tags.Role
    prefix: role
```

Validate discovered hosts:
```bash
ansible-inventory -i inventory_aws_ec2.yaml --graph
ansible-inventory -i inventory_aws_ec2.yaml --list
```

Always inspect inventory output before applying changes.

---

## 8) Ansible + Terraform integration patterns

### Pattern A: Terraform provisions, Ansible configures
1. Terraform creates infrastructure.
2. Ansible configures OS/services/apps.

### Pattern B: CI/CD orchestrates both
- pipeline runs Terraform plan/apply with approvals
- then runs Ansible against scoped hosts

Best practice:
- avoid overusing Terraform `local-exec` provisioners for long-term config mgmt
- prefer explicit Ansible execution in CI/CD stages

---

## 9) Ansible in CI/CD

### Safe pipeline sequence
1. `ansible-lint`
2. `ansible-playbook --syntax-check`
3. `ansible-playbook --list-tasks`
4. optional `--check --diff`
5. apply to dev
6. smoke/health checks
7. promote to higher environments

Example commands:
```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook --syntax-check -i inventories/dev/hosts.ini playbooks/site.yaml
ansible-playbook --check --diff -i inventories/dev/hosts.ini playbooks/site.yaml
ansible-playbook -i inventories/dev/hosts.ini playbooks/site.yaml
```

---

## 10) Secrets management

### Never commit secrets
Do not store passwords/tokens/private keys in Git.

### Use Ansible Vault
```bash
ansible-vault create group_vars/prod/vault.yaml
ansible-playbook -i inventories/prod/hosts.ini playbooks/site.yaml --ask-vault-pass
```

### Or external secret stores
- AWS Secrets Manager
- HashiCorp Vault
- CI/CD secret manager

---

## 11) Security best practices

- least-privilege SSH users and sudo rules
- keep host key checking enabled
- scoped inventory targets (no broad `all` in production)
- restricted network ingress (SSH from trusted IPs only)
- no plaintext credentials in vars/files/templates
- treat Docker group membership as privileged access

---

## 12) Idempotency and reliability patterns

### Good patterns
- use built-in modules before shell commands
- set explicit states (`present`, `absent`, `started`, `stopped`)
- avoid non-deterministic tasks
- use retries for eventual consistency

Retry example:
```yaml
- name: Wait for app health
  ansible.builtin.uri:
    url: "http://127.0.0.1:8080/health"
    status_code: 200
  register: health
  retries: 12
  delay: 5
  until: health.status == 200
```

---

## 13) Common modules and when to use them

- `package` / `apt` / `yum` / `dnf`: install packages
- `service` / `systemd`: manage services
- `user`, `group`: identity management
- `copy`, `template`: config deployment
- `file`: permissions/ownership/directories
- `uri`: HTTP checks
- `community.docker.*`: Docker operations
- `kubernetes.core.k8s`: Kubernetes resource management

Prefer module semantics over `command`/`shell` unless required.

---

## 14) Testing and quality controls

### Local checks
```bash
ansible-lint
ansible-playbook --syntax-check -i 'localhost,' -c local playbooks/site.yaml
ansible-playbook --list-tasks -i inventories/dev/hosts.ini playbooks/site.yaml
```

### Optional advanced testing
- Molecule for role-level scenario tests
- ephemeral test hosts/VMs/containers

---

## 15) Troubleshooting runbook

1. Confirm inventory target selection.
2. Run connectivity test:
```bash
ansible <group> -i <inventory> -m ping
```
3. Run playbook with verbosity:
```bash
ansible-playbook -i <inventory> playbooks/site.yaml -vvv
```
4. Inspect failed task module output.
5. Verify remote OS compatibility (`apt` vs `yum`).
6. Re-run with narrowed `--limit` scope.

Common failure causes:
- wrong SSH user/key
- missing sudo privilege
- package manager mismatch
- inventory filters selecting zero or too many hosts

---

## 16) Rollback and deployment safety

- use small batches (`serial`) for critical hosts
- keep previous app release and symlink-based deploys
- gate production runs with approvals
- run health checks after changes
- document rollback command path

Example rolling strategy:
```yaml
- name: Deploy app safely
  hosts: app_servers
  serial: 1
  max_fail_percentage: 0
  tasks:
    - name: Deploy release
      ansible.builtin.include_role:
        name: app
```

---

## 17) Anti-patterns to avoid

- using `shell` for everything
- disabling host key checking globally
- running broad playbooks against `all` unintentionally
- storing secrets in clear text
- hardcoding environment-specific values in tasks
- giant monolithic playbooks without roles
- no post-deployment verification

---

## 18) Practical DevOps checklist for Ansible/CaC

- [ ] Playbooks are idempotent and role-based
- [ ] Inventory strategy is explicit and scoped
- [ ] Secrets are encrypted or externally managed
- [ ] `ansible-lint` and syntax checks in CI
- [ ] Environment separation (dev/staging/prod)
- [ ] Change approvals for production
- [ ] Health checks and rollback steps documented
- [ ] Access control and SSH hardening enforced

---

## 19) Example end-to-end workflow

1. Update role/playbook code in feature branch.
2. Run local lint/syntax/check mode.
3. Open PR and run CI validations.
4. Apply to development inventory.
5. Verify service and health endpoints.
6. Promote to staging/prod with approvals.
7. Record run logs and outcomes.

This is “configuration delivery” done with the same engineering rigor as app delivery.

---

## 20) Suggested additions for Module 15

Add reusable items:
- `requirements.yml` with pinned collections
- `inventories/dev`, `inventories/staging`, `inventories/prod`
- `scripts/ansible-validate.sh`
- `scripts/ansible-deploy-dev.sh`
- `runbooks/ansible-incident-response.md`

These upgrades make portfolio demos more production-minded.

---

## References

- Ansible docs: https://docs.ansible.com/
- Ansible best practices: https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html
- Ansible roles guide: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html
- AWS EC2 dynamic inventory plugin: https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html
- community.docker collection: https://docs.ansible.com/ansible/latest/collections/community/docker/
- kubernetes.core collection: https://docs.ansible.com/ansible/latest/collections/kubernetes/core/
