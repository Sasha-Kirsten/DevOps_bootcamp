#!/usr/bin/env bash
set -euo pipefail

# Run once on a fresh Ubuntu or Amazon Linux EC2 instance with sudo privileges.
# This installs Docker, enables it at boot, and permits the current user to run Docker.
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run this script as your normal SSH user, not as root." >&2
  exit 1
fi

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "Cannot determine the operating system." >&2
  exit 1
fi

case "${ID:-}" in
  ubuntu|debian)
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose-v2
    ;;
  amzn)
    sudo dnf install -y docker git
    ;;
  *)
    echo "Unsupported operating system: ${ID:-unknown}. Install Docker Engine and the Docker Compose plugin manually." >&2
    exit 1
    ;;
esac

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "Docker was installed and enabled. Sign out and reconnect before running Docker without sudo."
echo "Confirm with: docker version && docker compose version"
