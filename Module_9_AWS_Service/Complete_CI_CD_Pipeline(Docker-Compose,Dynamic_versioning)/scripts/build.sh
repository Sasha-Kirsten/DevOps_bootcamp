#!/usr/bin/env bash
set -euo pipefail

image_tag="${1:-$(./scripts/version.sh)}"
export IMAGE_TAG="$image_tag"
export IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-cicd-starter}"

echo "Building ${IMAGE_REPOSITORY}:${IMAGE_TAG}"
docker compose build app
