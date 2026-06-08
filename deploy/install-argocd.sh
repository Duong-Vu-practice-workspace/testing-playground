#!/usr/bin/env bash
set -euo pipefail

echo "=== Cai ArgoCD ==="

# Kiem tra da co namespace argocd chua
if kubectl get namespace argocd &>/dev/null; then
  echo "  Namespace argocd da ton tai"
else
  echo "  Tao namespace argocd..."
  kubectl create namespace argocd
fi

# Install ArgoCD
echo "  Install ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "  Cho ArgoCD san sang..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Get initial admin password
echo ""
echo "  ArgoCD da duoc cai!"
echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
