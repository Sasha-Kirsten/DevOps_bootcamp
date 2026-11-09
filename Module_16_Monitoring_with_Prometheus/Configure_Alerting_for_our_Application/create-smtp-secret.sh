#!/usr/bin/env bash
set -euo pipefail

namespace="${NAMESPACE:-monitoring}"
secret_name="${SMTP_SECRET_NAME:-smtp-auth}"

command -v kubectl >/dev/null || { echo "kubectl is required." >&2; exit 1; }

if [[ ! -t 0 ]]; then
  echo "Run this helper from an interactive terminal so it can securely prompt for the SMTP password." >&2
  exit 1
fi

printf 'SMTP password or app password (input is hidden): ' >&2
if ! IFS= read -r -s SMTP_PASSWORD; then
  printf '\nSMTP password input was cancelled; no Secret was created.\n' >&2
  exit 1
fi
printf '\n' >&2

if [[ -z "${SMTP_PASSWORD}" ]]; then
  echo "SMTP password cannot be empty; no Secret was created." >&2
  exit 1
fi

kubectl create secret generic "${secret_name}" \
  --namespace "${namespace}" \
  --from-literal=password="${SMTP_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

unset SMTP_PASSWORD
echo "Created or refreshed ${secret_name} in namespace ${namespace}."