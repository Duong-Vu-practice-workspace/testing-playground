#!/usr/bin/env bash
set -euo pipefail

# Manual update: ./update-config.sh <service-name> <image-tag>
# NOTE: GitHub Actions tu dong chay sau moi push, khong can dung script nay
# Chi su dung khi muon update thu cong

SERVICE_NAME="${1:?Usage: ./update-config.sh <service-name> <image-tag>}"
IMAGE_TAG="${2:?Usage: ./update-config.sh <service-name> <image-tag>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config-repos/$SERVICE_NAME"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Error: Config directory not found: $CONFIG_DIR"
  echo "Available services:"
  ls "$SCRIPT_DIR/config-repos/"
  exit 1
fi

echo "=== Cap nhat IMAGE_TAG cho $SERVICE_NAME ==="
echo "  Tag: $IMAGE_TAG"

sed -i "s/IMAGE_TAG_REPLACEMENT/$IMAGE_TAG/g" "$CONFIG_DIR/deployment.yaml"

echo "  Da cap nhat $CONFIG_DIR/deployment.yaml"
echo ""
echo "  De apply (manual):"
echo "    cd $CONFIG_DIR"
echo "    git add ."
echo "    git commit -m 'Update $SERVICE_NAME to $IMAGE_TAG'"
echo "    git push"
