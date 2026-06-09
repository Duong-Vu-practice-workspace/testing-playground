#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  SETUP FULL - 1 lần duy nhất từ đầu"
echo "========================================"

echo ""
echo "=== 1. Kiểm tra / khởi động k3s ==="
if k3s kubectl get nodes &>/dev/null; then
  echo "  k3s dang chay"
else
  echo "  Dang start k3s..."
  sudo systemctl start k3s
  k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
fi

echo ""
echo "=== 2. Tao namespace + secret ==="
bash "$SCRIPT_DIR/deploy/setup-namespace.sh"

echo ""
echo "=== 3. Cai ArgoCD ==="
bash "$SCRIPT_DIR/deploy/install-argocd.sh"

echo ""
echo "=== 4. Setup Cloudflare Tunnel ==="
bash "$SCRIPT_DIR/deploy/cloudflared/setup-tunnel.sh" || echo "  Tunnel co the da ton tai, skip"

docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d

echo ""
echo "========================================"
echo "  SETUP HOAN TAT!"
echo "========================================"
echo ""
echo "  ArgoCD:    https://dev2-argocd.vucongtuanduong.dpdns.org (admin)"
echo ""
echo "  Services (qua Traefik Ingress):"
echo "    gateway:              https://dev2-api.vucongtuanduong.dpdns.org"
echo "    assignment-service:   https://dev2-assignment.vucongtuanduong.dpdns.org"
echo "    submission-service:   https://dev2-submission.vucongtuanduong.dpdns.org"
echo "    grading-service:      https://dev2-grading.vucongtuanduong.dpdns.org"
echo "    result-service:       https://dev2-result.vucongtuanduong.dpdns.org"
echo "    notification-service: https://dev2-notification.vucongtuanduong.dpdns.org"
echo "    config-server:        https://dev2-config.vucongtuanduong.dpdns.org"
echo ""
echo "  Config repo: https://github.com/Duong-Vu-practice-workspace/grading-config-test2"
echo ""
echo "  Sau boot lai: bash start.sh"
