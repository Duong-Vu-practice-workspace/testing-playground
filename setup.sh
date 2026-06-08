#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  SETUP FULL - 1 lần duy nhất từ đầu"
echo "========================================"

echo ""
echo "=== 1. Kiểm tra / khởi động k3s ==="
if kubectl get nodes &>/dev/null; then
  echo "  k3s dang chay"
else
  echo "  Dang start k3s..."
  sudo systemctl start k3s
  kubectl wait --for=condition=Ready nodes --all --timeout=60s
fi

echo ""
echo "=== 2. Cai ArgoCD ==="
bash "$SCRIPT_DIR/deploy/install-argocd.sh"

echo ""
echo "=== 3. Setup Cloudflare Tunnel ==="
bash "$SCRIPT_DIR/deploy/cloudflared/setup-tunnel.sh" || echo "  Tunnel co the da ton tai, skip"
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d

echo ""
echo "=== 4. Tao namespace + secret + ArgoCD App ==="
bash "$SCRIPT_DIR/deploy/setup-namespace.sh"

echo ""
echo "========================================"
echo "  SETUP HOAN TAT!"
echo "========================================"
echo ""
echo "  ArgoCD:    https://dev1-argocd.vucongtuanduong.dpdns.org (admin)"
echo ""
echo "  Services:"
echo "    gateway:              https://dev1-api.vucongtuanduong.dpdns.org"
echo "    config-server:        http://config-server-service:8086"
echo "    assignment-service:   http://assignment-service:8081"
echo "    submission-service:   http://submission-service:8082"
echo "    grading-service:      http://grading-service:8083"
echo "    result-service:       http://result-service:8084"
echo "    notification-service: http://notification-service:8085"
echo ""
echo "  Sau boot lai: bash start.sh"
