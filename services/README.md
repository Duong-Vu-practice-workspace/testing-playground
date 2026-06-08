# Grading Platform - Microservice Architecture

Hệ thống chấm bài tự động cho môn Lập trình Web, kiến trúc microservice phân tán.

## Cấu trúc project

```
services/
├── common-lib/                 # Shared library (BaseEntity, DTO, config)
├── gateway/                    # API Gateway (Spring Cloud Gateway)
├── assignment-service/         # CRUD bài tập, test scenarios
├── submission-service/         # Upload file, MinIO, Kafka producer
├── grading-service/            # Testcontainers Docker Compose executor
├── result-service/             # Lưu kết quả, thống kê
├── notification-service/       # WebSocket + Kafka consumer
└── infra/
    ├── docker-compose.yml      # Local development
    └── k8s/                    # Kubernetes manifests
```

## Yêu cầu

- Java 21+
- Maven 3.9+
- Docker & Docker Compose
- PostgreSQL 16
- Kafka (KRaft mode)
- MinIO

## Local Development

### 1. Start Infrastructure

```bash
cd infra
docker-compose up -d postgres kafka minio keycloak
```

### 2. Build All Services

```bash
cd services
mvn clean install -DskipTests
```

### 3. Run Services

```bash
# Terminal 1: Assignment Service
cd assignment-service
mvn spring-boot:run

# Terminal 2: Submission Service
cd submission-service
mvn spring-boot:run

# Terminal 3: Grading Service
cd grading-service
mvn spring-boot:run

# Terminal 4: Result Service
cd result-service
mvn spring-boot:run

# Terminal 5: Notification Service
cd notification-service
mvn spring-boot:run

# Terminal 6: Gateway
cd gateway
mvn spring-boot:run
```

## Ports

| Service | Port |
|---------|------|
| Gateway | 8080 |
| Assignment Service | 8081 |
| Submission Service | 8082 |
| Grading Service | 8083 |
| Result Service | 8084 |
| Notification Service | 8085 |
| PostgreSQL | 5432 |
| Kafka | 9092 |
| MinIO API | 9000 |
| MinIO Console | 9001 |
| Keycloak | 8088 |

## Deployment to k3s

### 1. Build Docker Images

```bash
cd services
./deploy.sh
```

### 2. Apply Kubernetes Manifests

```bash
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
```

## API Endpoints

### Assignment Service (8081)
- `POST /api/v1/assignments` - Create assignment
- `GET /api/v1/assignments` - List assignments
- `POST /api/v1/assignments/{id}/scenarios` - Add test scenario

### Submission Service (8082)
- `POST /api/v1/submissions` - Submit code (multipart)
- `GET /api/v1/submissions/{id}` - Get submission

### Result Service (8084)
- `GET /api/v1/results/{submissionId}` - Get result
- `GET /api/v1/results/assignment/{id}` - Get assignment results

### Notification Service (8085)
- `WS /ws/notifications?token=xxx` - WebSocket
- `GET /api/v1/notifications/history` - History

## Grading Flow

1. Student submits code via `POST /api/v1/submissions`
2. Submission Service uploads zip to MinIO
3. Submission Service sends message to Kafka topic `grading-jobs`
4. Grading Service consumes message
5. Grading Service extracts zip, runs Docker container
6. Grading Service executes test scenarios
7. Grading Service saves results via Result Service
8. Notification Service pushes real-time notification via WebSocket
