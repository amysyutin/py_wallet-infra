#!/usr/bin/env bash
set -euo pipefail

ARGO_NAMESPACE="${ARGO_NAMESPACE:-argocd}"
WORKLOAD_NAMESPACE="${WORKLOAD_NAMESPACE:-py-wallet-dev}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-5m}"

command -v kubectl >/dev/null || {
  echo "kubectl is required" >&2
  exit 1
}

current_context=$(kubectl config current-context 2>/dev/null || true)
if [[ -z "${current_context}" ]]; then
  echo "No Kubernetes context is configured" >&2
  exit 1
fi

image_tag() {
  awk '$1 == "newTag:" { print $2; exit }' "$1"
}

verify_application() {
  local application="$1"
  local deployment="$2"
  local image_repository="$3"
  local kustomization="$4"
  local expected_tag
  local sync_status
  local health_status
  local actual_image

  expected_tag=$(image_tag "${kustomization}")
  [[ -n "${expected_tag}" ]] || {
    echo "No image tag found in ${kustomization}" >&2
    exit 1
  }

  sync_status=$(kubectl -n "${ARGO_NAMESPACE}" get application "${application}" -o jsonpath='{.status.sync.status}')
  health_status=$(kubectl -n "${ARGO_NAMESPACE}" get application "${application}" -o jsonpath='{.status.health.status}')

  if [[ "${sync_status}" != "Synced" || "${health_status}" != "Healthy" ]]; then
    echo "${application}: sync=${sync_status} health=${health_status}" >&2
    exit 1
  fi

  kubectl -n "${WORKLOAD_NAMESPACE}" rollout status "deployment/${deployment}" --timeout="${ROLLOUT_TIMEOUT}"
  actual_image=$(kubectl -n "${WORKLOAD_NAMESPACE}" get deployment "${deployment}" -o jsonpath='{.spec.template.spec.containers[0].image}')

  if [[ "${actual_image}" != "${image_repository}:${expected_tag}" ]]; then
    echo "${deployment}: expected ${image_repository}:${expected_tag}, got ${actual_image}" >&2
    exit 1
  fi

  echo "${application}: Synced Healthy, ${actual_image} rolled out"
}

verify_application \
  py-wallet \
  py-wallet \
  ghcr.io/amysyutin/py_wallet-api \
  manifests/app/kustomization.yaml

verify_application \
  py-wallet-front \
  py-wallet-front \
  ghcr.io/amysyutin/py_wallet-front \
  manifests/frontend/kustomization.yaml

verify_application \
  py-wallet-snapshot-service \
  py-wallet-snapshot-service \
  ghcr.io/amysyutin/py_wallet-snapshot-service \
  manifests/snapshot-service/kustomization.yaml
