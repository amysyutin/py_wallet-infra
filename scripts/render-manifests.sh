#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT_DIRECTORY" >&2
  exit 2
fi

if ! command -v kustomize >/dev/null 2>&1; then
  echo "kustomize is required" >&2
  exit 1
fi

output_directory=$1
mkdir -p "${output_directory}"

roots=(
  manifests/app
  manifests/cluster
  manifests/frontend
  manifests/monitoring
  manifests/postgres
  manifests/snapshot-service
)

for root in "${roots[@]}"; do
  output_name=${root//\//-}.yaml
  echo "Rendering ${root}"
  kustomize build "${root}" > "${output_directory}/${output_name}"
done
