#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-vucongtuanduong.dpdns.org}"
TUNNEL_NAME="${2:-dev2-web-grading}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Creating cloudflared tunnel: ${TUNNEL_NAME} ==="
if cloudflared tunnel info "${TUNNEL_NAME}" &>/dev/null; then
  echo "Tunnel ${TUNNEL_NAME} already exists, skipping creation"
else
  cloudflared tunnel create "${TUNNEL_NAME}"
fi

TUNNEL_ID=$(cloudflared tunnel info "${TUNNEL_NAME}" 2>&1 | grep -oP 'tunnel \K[a-f0-9-]+')
echo "Tunnel ID: ${TUNNEL_ID}"

echo ""
echo "=== Cap nhat config.yml ==="
sed -i "s|credentials-file:.*|credentials-file: /etc/cloudflared/${TUNNEL_ID}.json|" "${SCRIPT_DIR}/config.yml"

echo "=== Copy config.yml vao ~/.cloudflared/ ==="
cp "${SCRIPT_DIR}/config.yml" ~/.cloudflared/config.yml
chmod 755 ~/.cloudflared
chmod 644 ~/.cloudflared/config.yml
chmod 644 ~/.cloudflared/${TUNNEL_ID}.json 2>/dev/null || true

echo ""
echo "=== Route DNS ==="
for sub in api assignment submission grading result notification config argocd keycloak; do
  cloudflared tunnel route dns "${TUNNEL_NAME}" "dev2-${sub}.${DOMAIN}" || true
done

echo ""
echo "Neu route DNS loi, them CNAME records tai DNS provider:"
echo "  dev2-* CNAME -> ${TUNNEL_ID}.cfargotunnel.com"
