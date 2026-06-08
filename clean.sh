#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning ArgoCD ==="
kubectl delete namespace argocd --wait 2>/dev/null || true

echo "=== Cleaning web-grading ==="
kubectl delete namespace web-grading --wait 2>/dev/null || true

echo "=== Cleanup done ==="
