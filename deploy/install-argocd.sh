#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Installing ArgoCD on k3s ==="

k3s kubectl create namespace argocd --dry-run=client -o yaml | k3s kubectl apply -f -

k3s kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods to be created..."
sleep 10

echo "Waiting for ArgoCD server to be ready..."
k3s kubectl wait --namespace argocd \
  --for=condition=Ready pod \
  --all \
  --timeout=300s || true

# Configure ArgoCD to allow HTTP behind reverse proxy (Traefik)
k3s kubectl patch deployment argocd-server -n argocd --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--insecure"
  }
]'

# Apply Ingress for ArgoCD
k3s kubectl apply -f "$SCRIPT_DIR/argocd-ingress.yaml"

# Expose argocd-server service as ClusterIP (Traefik handles external access)
k3s kubectl patch svc -n argocd argocd-server --patch '{"spec": {"type": "ClusterIP"}}'

# Apply ArgoCD Application
k3s kubectl apply -f "$SCRIPT_DIR/argocd-apps/grading-app.yaml"

ARGO_PASSWORD=$(k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "=== ArgoCD installed ==="
echo "  URL:     https://dev2-argocd.vucongtuanduong.dpdns.org"
echo "  User:    admin"
echo "  Pass:    ${ARGO_PASSWORD}"
echo ""
echo "=== Next steps: ==="
echo "  1. Login to ArgoCD web UI"
echo "  2. Settings > Repositories > Connect repo > Via HTTPS"
echo "     - URL: https://github.com/Duong-Vu-practice-workspace/grading-config-test2.git"
echo "     - Username/Password: your github token"
