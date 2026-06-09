#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/argocd-apps/argocd-app-template.yaml"
SERVICES_FILE="$SCRIPT_DIR/argocd-apps/services.env"

echo "=== Installing ArgoCD ==="
k3s kubectl create namespace argocd --dry-run=client -o yaml | k3s kubectl apply -f -
k3s kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD server..."
k3s kubectl wait --namespace argocd --for=condition=Ready pod --all --timeout=300s || true

# Allow HTTP behind reverse proxy
k3s kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

# ArgoCD Ingress
k3s kubectl apply -f "$SCRIPT_DIR/argocd-ingress.yaml"
k3s kubectl patch svc -n argocd argocd-server --patch '{"spec": {"type": "ClusterIP"}}'

echo ""
echo "=== Creating per-service ArgoCD Applications ==="

# Delete old single app if exists
k3s kubectl delete application grading -n argocd --ignore-not-found

# Read services.env and create apps from template
while IFS=: read -r SERVICE_NAME CONFIG_REPO; do
  # Skip empty lines and comments
  [[ -z "$SERVICE_NAME" || "$SERVICE_NAME" == \#* ]] && continue
  
  # Substitute variables in template and apply
  sed -e "s|\${SERVICE_NAME}|${SERVICE_NAME}|g" \
      -e "s|\${CONFIG_REPO}|${CONFIG_REPO}|g" \
      "$TEMPLATE" | k3s kubectl apply -f -
  
  echo "  Created: grading-${SERVICE_NAME}"
done < "$SERVICES_FILE"

ARGO_PASSWORD=$(k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo ""
echo "=== ArgoCD ready ==="
echo "  URL:  https://dev2-argocd.vucongtuanduong.dpdns.org"
echo "  User: admin"
echo "  Pass: ${ARGO_PASSWORD}"
