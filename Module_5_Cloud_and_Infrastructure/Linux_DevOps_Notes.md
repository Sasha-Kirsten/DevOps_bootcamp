# Linux for DevOps — Practical Notes (with Examples)

## Why this matters
Linux is the default runtime for most servers, containers, and CI/CD runners. Strong Linux fundamentals help you debug faster, automate safely, and run production systems reliably.

---

## 1) Core shell workflow

### Essential navigation
- `pwd` → show current directory
- `ls -lah` → list files (human-readable, includes hidden)
- `cd /path` → move directory
- `mkdir -p path/to/dir` → create nested folders
- `cp -r src dst` → copy recursively
- `mv old new` → move/rename
- `rm -rf path` → force delete (dangerous)

Example:
```bash
mkdir -p ~/apps/api/releases
cp build/app.jar ~/apps/api/releases/app-1.2.0.jar
ls -lah ~/apps/api/releases
```

### Command chaining and safety
- `cmd1 && cmd2` → run cmd2 only if cmd1 succeeds
- `cmd1 || cmd2` → run cmd2 if cmd1 fails
- `set -euo pipefail` in scripts for strict mode

Example:
```bash
set -euo pipefail
./gradlew clean build && echo "Build succeeded"
```

---

## 2) Users, groups, permissions

### Key concepts
- Owner / Group / Others permission model
- `r` (read), `w` (write), `x` (execute)
- `sudo` for privileged actions

### Useful commands
- `id` → current user/groups
- `sudo adduser deploy` → create user
- `sudo usermod -aG sudo deploy` → add to sudo group
- `chown user:group file` → change owner
- `chmod 640 file` / `chmod 755 dir` → set permissions

Example (secure app folder):
```bash
sudo mkdir -p /opt/myapp
sudo chown -R deploy:deploy /opt/myapp
sudo chmod 750 /opt/myapp
```

Tip:
- Keep secrets readable only by the app user (`chmod 600`).

---

## 3) Process and service management (systemd)

### Process basics
- `ps aux | grep app`
- `top` / `htop`
- `kill -15 <pid>` graceful stop
- `kill -9 <pid>` forced stop

### systemd service lifecycle
- `systemctl status myapp`
- `systemctl start myapp`
- `systemctl stop myapp`
- `systemctl restart myapp`
- `systemctl enable myapp` (start on boot)

Example service file: `/etc/systemd/system/myapp.service`
```ini
[Unit]
Description=My Java App
After=network.target

[Service]
User=deploy
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/java -jar /opt/myapp/app.jar
Restart=always
RestartSec=5
Environment="SPRING_PROFILES_ACTIVE=prod"

[Install]
WantedBy=multi-user.target
```

Apply it:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
sudo systemctl status myapp
```

---

## 4) Logs and observability basics

### Journal logs
- `journalctl -u myapp -f` (follow service logs)
- `journalctl -u myapp --since "1 hour ago"`

### File logs
- `tail -f /var/log/nginx/error.log`
- `less /var/log/syslog`

### Quick triage pattern
1. Check service status
2. Read recent logs
3. Confirm port is listening
4. Confirm upstream dependency connectivity

Example:
```bash
systemctl status myapp
journalctl -u myapp -n 100 --no-pager
ss -tulpen | grep 8080
curl -v http://127.0.0.1:8080/health
```

---

## 5) Networking essentials for DevOps

### Commands you will use often
- `ip a` → interfaces and IPs
- `ip r` → routes
- `ss -tulpen` → listening ports/processes
- `dig example.com` / `nslookup` → DNS check
- `curl -I https://example.com` → HTTP headers
- `nc -zv host 5432` → test TCP connectivity

Example connectivity checks:
```bash
curl -fsS http://localhost:8080/health
nc -zv redis.internal 6379
dig +short api.example.com
```

### Firewall basics
On Ubuntu (`ufw`):
```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Principle: only open required ports.

---

## 6) Package and runtime management

### Apt (Debian/Ubuntu)
- `sudo apt update`
- `sudo apt upgrade -y`
- `sudo apt install -y curl jq unzip`

### Verify runtimes
- `java -version`
- `python3 --version`
- `docker --version`

Pin major versions in production where possible.

---

## 7) Disk, memory, and CPU checks

### Disk
- `df -h` → filesystem usage
- `du -sh *` → folder sizes
- `du -xh /var | sort -h | tail -20` → largest directories

### Memory/CPU
- `free -h`
- `vmstat 1 5`
- `uptime` (load averages)

Example low disk triage:
```bash
df -h
du -xh /var | sort -h | tail -20
sudo journalctl --vacuum-time=7d
```

---

## 8) SSH and secure remote operations

### Good defaults
- Use key auth (Ed25519 preferred)
- Disable password auth after validation
- Avoid root login for routine tasks

### Common operations
- `ssh deploy@server-ip`
- `scp app.jar deploy@server:/opt/myapp/`
- `ssh -i ~/.ssh/id_ed25519 deploy@server-ip`

SSH hardening file: `/etc/ssh/sshd_config`
```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Then:
```bash
sudo systemctl restart ssh
```

---

## 9) Text processing for troubleshooting

### Search and filter
- `grep -R "ERROR" /var/log/myapp`
- `awk '{print $1}' file`
- `sed 's/old/new/g' file`
- `cut -d':' -f1 /etc/passwd`

### JSON on CLI
- `jq` is essential for APIs

Example:
```bash
curl -s https://api.github.com/repos/kubernetes/kubernetes | jq '.stargazers_count'
```

---

## 10) Scripting for repeatable ops

### Script template
```bash
#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

APP_DIR="/opt/myapp"
ARTIFACT="app.jar"

log "Starting deploy"
install -d "$APP_DIR"
cp "$ARTIFACT" "$APP_DIR/$ARTIFACT"
sudo systemctl restart myapp
log "Deploy complete"
```

Make executable:
```bash
chmod +x deploy.sh
```

---

## 11) Cron jobs and scheduled operations

### Cron basics
- `crontab -e` edit schedule
- `crontab -l` list jobs

Example: daily backup at 2:30 AM
```cron
30 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

Tip: prefer systemd timers for modern Linux where possible.

---

## 12) Linux + Containers + Kubernetes context

### Docker quick checks
- `docker ps -a`
- `docker logs <container>`
- `docker exec -it <container> sh`
- `docker system df`

### Kubernetes quick checks
- `kubectl get pods -A`
- `kubectl describe pod <name> -n <ns>`
- `kubectl logs <pod> -n <ns>`
- `kubectl top pods -A` (if metrics server exists)

When in doubt, check events:
```bash
kubectl get events -A --sort-by=.lastTimestamp | tail -50
```

---

## 13) Security hygiene checklist

- Patch OS regularly.
- Use least privilege users.
- Keep secrets out of Git.
- Rotate credentials and keys.
- Restrict inbound ports.
- Enable audit trails and central logs.
- Add backups + restore tests.

---

## 14) Incident mini-runbook (copy/paste mindset)

1. **What changed?** (deploy/config/network/secret)
2. **Is service up?** `systemctl status ...`
3. **Are logs clean?** `journalctl -u ... -n 200`
4. **Is port open?** `ss -tulpen | grep <port>`
5. **Dependency reachability?** `nc -zv host port`
6. **Resource exhaustion?** `df -h`, `free -h`, `uptime`
7. **Rollback if needed** to last known good artifact.

---

## 15) High-value commands cheat sheet

```bash
# health endpoint
curl -fsS http://localhost:8080/health

# find biggest disk consumers
sudo du -xh / | sort -h | tail -30

# service logs live
journalctl -u myapp -f

# open ports + owners
ss -tulpen

# process tree
ps -ef --forest

# kill process on a port (example 8080)
kill -15 $(lsof -t -i:8080)
```

---

## Suggested next steps for this repository

1. Add a `scripts/linux/` folder with reusable scripts:
   - `deploy.sh`
   - `healthcheck.sh`
   - `backup.sh`
2. Add a `systemd/` folder with service examples.
3. Add a `troubleshooting.md` per module with module-specific checks.
4. Add a security baseline checklist to each infrastructure module.
