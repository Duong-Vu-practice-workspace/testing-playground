#!/bin/bash
set -e

echo "=== Building all services ==="

cd services

# Build all services
echo "Building common-lib..."
cd common-lib
mvn clean install -DskipTests
cd ..

# Build and package each service
services=("assignment-service" "submission-service" "grading-service" "result-service" "notification-service" "gateway")

for service in "${services[@]}"; do
    echo "Building $service..."
    cd $service
    mvn clean package -DskipTests
    cd ..
done

echo "=== Building Docker images ==="

# Build Docker images
for service in "${services[@]}"; do
    echo "Building Docker image for $service..."
    docker build -t grading/$service:latest $service/
done

echo "=== Deploying to Kubernetes ==="

# Apply Kubernetes manifests
kubectl apply -f infra/k8s/namespace.yml
kubectl apply -f infra/k8s/postgres/
kubectl apply -f infra/k8s/kafka/
kubectl apply -f infra/k8s/minio.yml
kubectl apply -f infra/k8s/keycloak/
kubectl apply -f infra/k8s/gateway/
kubectl apply -f infra/k8s/assignment-service/
kubectl apply -f infra/k8s/submission-service/
kubectl apply -f infra/k8s/grading-service/
kubectl apply -f infra/k8s/result-service/
kubectl apply -f infra/k8s/notification-service/

echo "=== Deployment complete ==="
echo "Gateway: http://localhost:8080"
echo "Keycloak: http://localhost:8088"
echo "MinIO Console: http://localhost:9001"
