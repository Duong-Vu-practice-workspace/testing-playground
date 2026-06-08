#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAMESPACE="${1:-web-grading}"

echo "=== Tao namespace ${NAMESPACE} ==="
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Tao secret tu .env ==="
if [ -f "${SCRIPT_DIR}/../.env" ]; then
  set -o allexport
  source "${SCRIPT_DIR}/../.env"
  set +o allexport
fi

# Database secrets
kubectl create secret generic db-secret \
  --namespace "${NAMESPACE}" \
  --from-literal=DB_HOST="${DB_HOST:-postgres-service}" \
  --from-literal=DB_PORT="${DB_PORT:-5432}" \
  --from-literal=DB_USERNAME="${DB_USERNAME:-postgres}" \
  --from-literal=DB_PASSWORD="${DB_PASSWORD:-postgres}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== Apply ArgoCD Applications ==="
for app in "$SCRIPT_DIR"/argocd-apps/*.yaml; do
  echo "  Applying $(basename "$app")..."
  kubectl apply -f "$app"
done
