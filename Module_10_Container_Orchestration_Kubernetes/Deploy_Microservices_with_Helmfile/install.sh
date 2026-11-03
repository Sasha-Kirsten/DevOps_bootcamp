#!/usr/bin/env bash
set -euo pipefail

if [[ "${CONFIRM_DEPLOY:-}" != "yes" ]]; then
	echo "Refusing to modify a cluster. Re-run with CONFIRM_DEPLOY=yes after reviewing the active kubeconfig context." >&2
	exit 1
fi

command -v helmfile >/dev/null || { echo "helmfile is required." >&2; exit 1; }
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

helmfile --file "${script_dir}/helmfile.yaml" sync "$@"
 