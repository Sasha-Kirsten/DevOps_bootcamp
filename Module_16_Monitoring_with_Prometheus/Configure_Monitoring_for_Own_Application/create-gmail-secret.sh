#!/usr/bin/env bash
set -euo pipefail

namespace="monitoring"
secret_name="gmail-auth"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but was not found on PATH." >&2
  exit 1
fi

if [[ ! -t 0 ]]; then
  echo "Run this script from an interactive terminal so the App Password can be entered securely." >&2
  exit 1
fi

read -r -s -p "Gmail App Password (input is hidden): " gmail_app_password
echo

if [[ -z "${gmail_app_password}" ]]; then
  echo "No App Password was provided; the Secret was not changed." >&2
  exit 1
fi

kubectl create secret generic "${secret_name}" \
  --namespace "${namespace}" \
  --from-literal=password="${gmail_app_password}" \
  --dry-run=client -o yaml | kubectl apply -f -

unset gmail_app_password
echo "Secret/${secret_name} is ready in namespace ${namespace}."