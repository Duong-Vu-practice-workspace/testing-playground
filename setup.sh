#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  Grading Platform - Full Setup"
echo "========================================"

echo ""
echo "=== 1. Kiem tra / khoi dong k3s ==="
if k3s kubectl get nodes &>/dev/null; then
  echo "  k3s dang chay"
else
  echo "  Dang start k3s..."
  sudo systemctl start k3s
  k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
fi

echo ""
echo "=== 2. Tao namespace + DB secret ==="
bash "$SCRIPT_DIR/deploy/setup-namespace.sh"

echo ""
echo "=== 3. Cai ArgoCD + per-service apps ==="
bash "$SCRIPT_DIR/deploy/install-argocd.sh"

echo ""
echo "=== 4. Deploy Keycloak ==="
bash "$SCRIPT_DIR/deploy/setup-keycloak.sh"

echo ""
echo "=== 5. Setup Cloudflare Tunnel ==="
bash "$SCRIPT_DIR/deploy/cloudflared/setup-tunnel.sh" || echo "  Tunnel co the da ton tai, skip"
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d

echo ""
echo "========================================"
echo "  SETUP HOAN TAT!"
echo "========================================"
echo ""
echo "  ArgoCD:     https://dev2-argocd.vucongtuanduong.dpdns.org"
echo "  Keycloak:   https://dev2-keycloak.vucongtuanduong.dpdns.org/admin/"
echo ""
echo "  API Gateway: https://dev2-api.vucongtuanduong.dpdns.org"
echo ""
echo "  Services:"
echo "    assignment:   https://dev2-assignment.vucongtuanduong.dpdns.org"
echo "    submission:   https://dev2-submission.vucongtuanduong.dpdns.org"
echo "    grading:      https://dev2-grading.vucongtuanduong.dpdns.org"
echo "    result:       https://dev2-result.vucongtuanduong.dpdns.org"
echo "    notification: https://dev2-notification.vucongtuanduong.dpdns.org"
echo "    config:       https://dev2-config.vucongtuanduong.dpdns.org"
echo ""
echo "  Keycloak creds: admin / admin"
echo "  Realm: grading-platform, Client: grading-client"
echo "  Test user: student1 / student1"
echo ""
echo "  Sau boot lai: bash start.sh"
