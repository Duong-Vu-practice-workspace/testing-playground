# Web Programming Grading Platform - GitOps

## Kien truc

```
Source Repo                          Config Repo
(grading-<service>-test2)           (grading-<service>-config-test2)
┌─────────────────────┐             ┌─────────────────────┐
│ src/                │             │ deployment.yaml     │
│ pom.xml             │──── CI ────│ service.yaml        │
│ Dockerfile          │             │                     │
│ .github/workflows/  │             │ ArgoCD watches      │
└─────────────────────┘             └──────────┬──────────┘
                                               │
                                               v
                                        ┌──────────────┐
                                        │   ArgoCD     │
                                        │   (CD)       │
                                        └──────┬───────┘
                                               │
                                               v
                                        ┌──────────────┐
                                        │   k3s        │
                                        │   (Deploy)   │
                                        └──────────────┘
```

## Luong lam viec

1. Developer push code vao Source Repo
2. GitHub Actions tu dong:
   - Build Maven
   - Push Docker image len Docker Hub (tag: `latest`, `<sha>`)
   - Cap nhat IMAGE_TAG trong Config Repo
3. ArgoCD detect change trong Config Repo
4. ArgoCD sync deployment len k3s

## Setup

### Buoc 1: Tao repos tren GitHub

Moi service can 2 repos:
- `grading-<service>-test2` (source)
- `grading-<service>-config-test2` (config)

### Buoc 2: Tao secrets trong Source Repo

Vao Source Repo > Settings > Secrets and variables > Actions:

| Secret | Gia tri |
|--------|---------|
| `CONFIG_REPO_TOKEN` | GitHub PAT voi quyen `repo` |
| `DOCKERHUB_USERNAME` | Username Docker Hub |
| `DOCKERHUB_TOKEN` | Token Docker Hub |

### Buoc 3: Deploy ArgoCD Applications

```bash
kubectl apply -f deploy/argocd-apps/gateway.yaml
kubectl apply -f deploy/argocd-apps/assignment-service.yaml
# ... cac service khac
```

### Buoc 4: Update config thu cong (neu can)

```bash
./update-config.sh assignment-service abc123
cd config-repos/assignment-service
git add . && git commit -m "Update" && git push
```

## Danh sach repos

| Service | Source Repo | Config Repo |
|---------|-------------|-------------|
| config-server | grading-config-server-test2 | grading-config-server-config-test2 |
| gateway | grading-gateway-test2 | grading-gateway-config-test2 |
| assignment-service | grading-assignment-service-test2 | grading-assignment-service-config-test2 |
| submission-service | grading-submission-service-test2 | grading-submission-service-config-test2 |
| grading-service | grading-executor-service-test2 | grading-executor-service-config-test2 |
| result-service | grading-result-service-test2 | grading-result-service-config-test2 |
| notification-service | grading-notification-service-test2 | grading-notification-service-config-test2 |
| common-lib | grading-common-lib-test2 | - |
