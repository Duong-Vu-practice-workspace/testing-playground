#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-vucongtuanduong.dpdns.org}"
TUNNEL_NAME="${2:-dev1-web-grading}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Creating cloudflared tunnel: ${TUNNEL_NAME} ==="
if cloudflared tunnel info "${TUNNEL_NAME}" &>/dev/null; then
  echo "Tunnel ${TUNNEL_NAME} already exists, skipping creation"
else
  cloudflared tunnel create "${TUNNEL_NAME}"
fi

TUNNEL_ID=$(cloudflared tunnel info "${TUNNEL_NAME}" 2>&1 | grep -oP 'tunnel \K[a-f0-9-]+')
echo ""
echo "=== Tunnel ID: ${TUNNEL_ID} ==="

echo ""
echo "=== Cap nhat config.yml ==="
sed -i "s/tunnel: .*/tunnel: ${TUNNEL_ID}/" "${SCRIPT_DIR}/config.yml"
sed -i "s|credentials-file:.*|credentials-file: /etc/cloudflared/${TUNNEL_ID}.json|" "${SCRIPT_DIR}/config.yml"

echo "=== Copy config.yml vao ~/.cloudflared/ + fix permissions ==="
cp "${SCRIPT_DIR}/config.yml" ~/.cloudflared/config.yml
chmod 755 ~/.cloudflared
chmod 644 ~/.cloudflared/config.yml
chmod 644 ~/.cloudflared/${TUNNEL_ID}.json
echo "Done"

echo ""
echo "=== Route DNS ==="
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-api.${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-assignment.${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-submission.${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-grading.${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-result.${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-notification.${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-argocd.${DOMAIN}" || true

echo ""
echo "=== Neu route DNS loi (domain khong tren Cloudflare): ==="
echo "Them CNAME records tai DNS provider (dpdns.org):"
echo "  dev1-api         CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-assignment  CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-submission  CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-grading     CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-result      CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-notification CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-argocd      CNAME -> ${TUNNEL_ID}.cfargotunnel.com"

echo ""
echo "Xong thi chay:"
echo "  docker compose -f ${SCRIPT_DIR}/docker-compose.yml up -d"
