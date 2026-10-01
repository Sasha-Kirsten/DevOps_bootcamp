#!/usr/bin/env bash
set -euo pipefail

# This script publishes a previously built image. It intentionally does not
# contain registry credentials: Jenkins should inject them as credentials.
: "${REGISTRY_HOST:?Set REGISTRY_HOST, for example registry.example.com}"
: "${IMAGE_NAME:?Set IMAGE_NAME, for example your-user/cicd-starter}"

image_tag="${1:?Provide the image tag to publish}"
source_image="${IMAGE_REPOSITORY:-cicd-starter}:${image_tag}"
target_image="${REGISTRY_HOST}/${IMAGE_NAME}:${image_tag}"

echo "Tagging ${source_image} as ${target_image}"
docker image tag "$source_image" "$target_image"
echo "Pushing ${target_image}"
docker image push "$target_image"

echo "Image published. Add your own deployment command below (ECS, EKS, or another target)."
