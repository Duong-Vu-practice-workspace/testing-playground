#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAMESPACE="${1:-web-grading}"

echo "=== Creating ${NAMESPACE} namespace ==="
k3s kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | k3s kubectl apply -f -

echo "=== Creating secrets from .env ==="
if [ -f "${SCRIPT_DIR}/../.env" ]; then
  set -o allexport
  source "${SCRIPT_DIR}/../.env"
  set +o allexport
fi

# Database secrets
k3s kubectl create secret generic db-secret \
  --namespace "${NAMESPACE}" \
  --from-literal=DB_HOST="${DB_HOST:-postgres-service}" \
  --from-literal=DB_PORT="${DB_PORT:-5432}" \
  --from-literal=DB_USERNAME="${DB_USERNAME:-postgres}" \
  --from-literal=DB_PASSWORD="${DB_PASSWORD:-postgres}" \
  --dry-run=client -o yaml | k3s kubectl apply -f -

echo "Namespace and secrets created"
