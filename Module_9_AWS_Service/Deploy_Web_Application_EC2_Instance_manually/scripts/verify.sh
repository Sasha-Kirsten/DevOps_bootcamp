#!/usr/bin/env bash
set -euo pipefail

# Run on the EC2 instance after deployment.
docker compose ps
curl --fail --silent --show-error http://localhost/health
echo
