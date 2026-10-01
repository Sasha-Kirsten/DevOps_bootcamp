#!/usr/bin/env bash
set -euo pipefail

# Emits a SemVer-compatible build tag. Jenkins uses BUILD_NUMBER to make CI tags
# unique without creating Git tags automatically.
base_version="${BASE_VERSION:-0.1.0}"

if [[ ! "$base_version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "BASE_VERSION must use MAJOR.MINOR.PATCH format; received: $base_version" >&2
  exit 1
fi

if [[ -n "${BUILD_NUMBER:-}" ]]; then
  printf '%s-ci.%s\n' "$base_version" "$BUILD_NUMBER"
else
  printf '%s-local\n' "$base_version"
fi
