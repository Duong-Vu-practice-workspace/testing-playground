#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAMESPACE="web-grading"

echo "=== Deploying Keycloak ==="
k3s kubectl apply -n "${NAMESPACE}" -f "$SCRIPT_DIR/keycloak/keycloak.yaml"

echo "Waiting for Keycloak to start (first boot ~3min)..."
k3s kubectl rollout status deployment/keycloak -n "${NAMESPACE}" --timeout=600s

echo ""
echo "=== Configuring Keycloak ==="

sleep 10
KEYCLOAK_POD=$(k3s kubectl get pod -n "${NAMESPACE}" -l app=keycloak -o jsonpath='{.items[0].metadata.name}')

# Authenticate
k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password admin

# Create realm
echo "  Creating realm: grading-platform"
k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh create realms \
  -s realm=grading-platform -s enabled=true -s displayName="Grading Platform"

# Create client
echo "  Creating client: grading-client"
k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh create clients -r grading-platform \
  -s clientId=grading-client -s enabled=true -s publicClient=true \
  -s 'redirectUris=["*"]' -s 'webOrigins=["*"]' -s directAccessGrantsEnabled=true

# Create users
echo "  Creating users..."
k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh create users -r grading-platform \
  -s username=student1 -s email=student1@test.com -s emailVerified=true \
  -s firstName=Student -s lastName=One -s enabled=true
k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh set-password -r grading-platform \
  --username student1 --new-password student1

k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh create users -r grading-platform \
  -s username=teacher1 -s email=teacher1@test.com -s emailVerified=true \
  -s firstName=Teacher -s lastName=One -s enabled=true
k3s kubectl exec -n "${NAMESPACE}" "$KEYCLOAK_POD" -- \
  /opt/keycloak/bin/kcadm.sh set-password -r grading-platform \
  --username teacher1 --new-password teacher1

echo ""
echo "=== Keycloak ready ==="
echo "  Admin:  admin/admin"
echo "  Realm:  grading-platform"
echo "  Client: grading-client"
echo "  Users:  student1/student1, teacher1/teacher1"
