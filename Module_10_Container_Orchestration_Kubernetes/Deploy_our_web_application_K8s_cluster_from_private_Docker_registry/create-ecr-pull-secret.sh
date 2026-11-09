#!/usr/bin/env bash
set -euo pipefail

# Load only local placeholder values. Never commit real AWS credentials here.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${script_dir}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${script_dir}/.env"
fi

: "${AWS_REGION:?Set AWS_REGION in .env or your environment.}"
: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID in .env or your environment.}"
: "${ECR_REPOSITORY:?Set ECR_REPOSITORY in .env or your environment.}"
: "${NAMESPACE:=private-ecr-demo}"

command -v aws >/dev/null || { echo "aws CLI is required." >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required." >&2; exit 1; }

ecr_registry="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws sts get-caller-identity >/dev/null
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry my-registry-key \
  --namespace "${NAMESPACE}" \
  --docker-server="${ecr_registry}" \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region "${AWS_REGION}")" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created or refreshed my-registry-key in namespace ${NAMESPACE}."