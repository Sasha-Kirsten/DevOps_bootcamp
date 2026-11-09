#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
values_file="${1:-${script_dir}/redis-exporter-values.yaml}"
chart="prometheus-community/prometheus-redis-exporter"
chart_version="6.37.0"
release_name="third-party-redis-exporter"
namespace="monitoring"
rendered_manifest="$(mktemp)"
trap 'rm -f "${rendered_manifest}"' EXIT

command -v helm >/dev/null || { echo "helm is required." >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required." >&2; exit 1; }

if grep -q 'replace-with-third-party-redis-hostname' "${values_file}"; then
  echo "The values file still contains the endpoint placeholder." >&2
  echo "Copy redis-exporter-values.yaml to the ignored redis-exporter-values.local.yaml and add approved provider values." >&2
  exit 1
fi

kubectl apply --dry-run=server -f "${script_dir}/redis-alert-rules.yaml"

helm template "${release_name}" "${chart}" \
  --version "${chart_version}" \
  --namespace "${namespace}" \
  --values "${values_file}" \
  --api-versions monitoring.coreos.com/v1 > "${rendered_manifest}"

kubectl apply --dry-run=server -f "${rendered_manifest}"
echo "Static validation passed. This does not test DNS, TLS, credentials, network access, or Redis metrics."