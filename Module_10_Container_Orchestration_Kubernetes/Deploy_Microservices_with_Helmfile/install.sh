#!/usr/bin/env bash
set -euo pipefail

if [[ "${CONFIRM_DEPLOY:-}" != "yes" ]]; then
	echo "Refusing to modify a cluster. Re-run with CONFIRM_DEPLOY=yes after reviewing the active kubeconfig context." >&2
	exit 1
fi

command -v helmfile >/dev/null || { echo "helmfile is required." >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required to inspect the target context." >&2; exit 1; }
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# TODO: For production, restrict deployments to explicitly allow-listed contexts
# or use a CI-provided kubeconfig rather than a developer's default context.
echo "Target Kubernetes context: $(kubectl config current-context)"
helmfile --file "${script_dir}/helmfile.yaml" sync "$@"
 