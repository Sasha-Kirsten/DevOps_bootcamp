#!/usr/bin/env bash
set -euo pipefail

# Run from the directory that contains docker-compose.yml on the EC2 instance.
# Expected usage: ./scripts/deploy.sh <registry/image> <immutable-tag>
image_repository="${1:?Provide an image repository, for example registry.example.com/team/ec2-web-starter}"
image_tag="${2:?Provide an immutable image tag, for example 1.0.0}"

if [[ "$image_repository" == *"example.com"* ]]; then
  echo "Replace the example registry with your real image repository." >&2
  exit 1
fi

cat > .env <<EOF
IMAGE_REPOSITORY=${image_repository}
IMAGE_TAG=${image_tag}
HOST_PORT=80
EOF

echo "Pulling ${image_repository}:${image_tag}"
docker compose pull web
docker compose up -d --no-build --remove-orphans

echo "Waiting for the container health check..."
for _ in {1..12}; do
  if [[ "$(docker compose ps --format json web | grep -o 'healthy' || true)" == "healthy" ]]; then
    echo "Deployment healthy: http://$(curl -fsS http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')/"
    exit 0
  fi
  sleep 5
done

echo "Deployment did not become healthy. Inspect with: docker compose logs web" >&2
exit 1
