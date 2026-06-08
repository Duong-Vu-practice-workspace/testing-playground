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

```bash
pip install requests
python3 create-repos.py <github-token> <org-name> [private]
```

### Buoc 2: Setup Organization Secrets

Organization secrets duoc share giua tat ca repos, khong can set tung repo.

Vao: `https://github.com/<org>/settings/secrets/actions`

Tao cac secrets:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | Username Docker Hub |
| `DOCKERHUB_TOKEN` | Token Docker Hub |
| `CONFIG_REPO_TOKEN` | GitHub PAT voi quyen `repo` |

Chon visibility: **All repositories**

### Buoc 3: Push code vao repos

```bash
pip install requests gitpython
python3 setup-repos.py <github-token> <org-name>
```

### Buoc 4: Deploy ArgoCD Applications

```bash
kubectl apply -f deploy/argocd-apps/gateway.yaml
kubectl apply -f deploy/argocd-apps/assignment-service.yaml
# ... cac service khac
```

### Buoc 5: Start Cloudflare Tunnel

```bash
bash deploy/cloudflared/setup-tunnel.sh
docker compose -f deploy/cloudflared/docker-compose.yml up -d
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
| config (Spring) | grading-config-test2 | - |

## Scripts

| Script | Muc dich |
|--------|----------|
| `create-repos.py` | Tao 16 repos tren GitHub |
| `setup-repos.py` | Push code vao tung repo |
| `update-config.sh` | Update IMAGE_TAG thu cong (neu can) |
| `split-repos.sh` | Huong dan tach repo |
