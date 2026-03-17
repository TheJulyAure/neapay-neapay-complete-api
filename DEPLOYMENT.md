# NeaPay Complete - Deployment Pipeline Documentation

## Overview

This deployment pipeline provides automated CI/CD workflows for building, testing, and deploying NeaPay Complete across multiple environments (staging and production).

## Architecture

### GitHub Actions Workflows

1. **Build & Test** (`.github/workflows/build-and-test.yml`)
   - Runs on: Push to `main`/`develop`, Pull Requests
   - Tests API and Frontend separately
   - Builds and pushes Docker images to GHCR

2. **Deploy to Staging** (`.github/workflows/deploy-staging.yml`)
   - Runs on: Push to `develop` branch
   - Deploys to staging server via SSH
   - Runs health checks and smoke tests
   - Notifies Slack on success/failure

3. **Deploy to Production** (`.github/workflows/deploy-production.yml`)
   - Runs on: Push to `main` branch or manual trigger
   - Blue-green deployment strategy
   - Automatic rollback on health check failure
   - Database backups before deployment

### Deployment Files

- **docker-compose.staging.yml** - Staging configuration with all services
- **docker-compose.production.yml** - Production config with resource limits, monitoring, logging
- **deploy.sh** - Automated bash deployment script
- **deploy-cli.sh** - CLI interface for local deployments

### Kubernetes

- **k8s/neapay-namespace.yaml** - Namespace, RBAC, NetworkPolicies, ConfigMaps, Secrets
- **k8s/neapay-api-deployment.yaml** - API Deployment, Service, HPA, PDB
- **k8s/neapay-frontend-deployment.yaml** - Frontend Deployment, Service, HPA, PDB

## Quick Start

### Prerequisites

```bash
# Install dependencies
git clone <repo>
cd neapay-complete

# Create .env file
cp .env.example .env
# Edit .env with your values
```

### Local Testing

```bash
# Build images
./deploy-cli.sh build

# Start staging
./deploy-cli.sh staging-up

# View logs
./deploy-cli.sh staging-logs

# Stop
./deploy-cli.sh staging-down
```

### GitHub Actions Setup

1. Create GitHub repository secrets:

```bash
# Staging
STAGING_HOST=staging.neapay.com
STAGING_USER=deploy
STAGING_SSH_KEY=<private_key>

# Production
PROD_HOST=api.neapay.com
PROD_USER=deploy
PROD_SSH_KEY=<private_key>

# Notifications
SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

2. Container registry access:
   - Ensure the runner has access to GHCR
   - Use `docker/login-action@v3` (GitHub automatically provides `secrets.GITHUB_TOKEN`)

### Staging Deployment

Push to `develop` branch:

```bash
git commit -m "Update staging"
git push origin develop
```

GitHub Actions will:
1. Build and test code
2. Push images to GHCR
3. SSH into staging server
4. Pull latest code and images
5. Run `docker compose` with staging config
6. Execute smoke tests
7. Notify Slack

### Production Deployment

Push to `main` branch:

```bash
git commit -m "Release v1.2.0"
git push origin main
```

GitHub Actions will:
1. Build and test code
2. Push images to GHCR
3. SSH into production server
4. Backup current database and images
5. Pull new images
6. Deploy using blue-green strategy
7. Health checks on new services
8. Automatic rollback if checks fail
9. Notify Slack

### Manual Deployment

If GitHub Actions is unavailable:

```bash
# SSH into server
ssh deploy@prod.neapay.com

# Deploy
cd /opt/neapay-complete
./deploy.sh production

# Check logs
./deploy-cli.sh prod-logs
```

## Environment Configurations

### Staging (docker-compose.staging.yml)

- Single replica of each service
- Debug logging enabled
- Resource limits: API 1GB, Frontend 512MB
- 3-day data retention
- Health checks every 10s

### Production (docker-compose.production.yml)

- Multiple replicas for redundancy
- Info-level logging
- Strict resource limits: API 2GB, Frontend 512MB
- 30-day Prometheus retention
- Grafana monitoring included
- Health checks with 30s startup period
- Persistent volumes with backups

## Monitoring & Logging

### Built-in Services

- **Prometheus** (`:9090`) - Metrics collection
- **Grafana** (`:3001`) - Visualization (requires GRAFANA_PASSWORD)

### View Logs

```bash
# Staging
docker compose -f docker-compose.yml -f docker-compose.staging.yml logs -f [service]

# Production
docker compose -f docker-compose.yml -f docker-compose.production.yml logs -f [service]

# Kubernetes
kubectl logs -f deployment/neapay-api -n neapay
kubectl logs -f deployment/neapay-frontend -n neapay
```

### Health Checks

All services include:
- Liveness probe: Detects if service is running
- Readiness probe: Detects if service can accept traffic
- Startup period: Gives service time to initialize

## Backup & Recovery

### Automatic Backups

Backups are created before each production deployment:

```
/opt/neapay-backups/
├── 20240115_143022/
│   ├── images.txt           # Docker images in use
│   ├── services.txt         # Running services
│   ├── postgres-backup.sql  # PostgreSQL dump
│   └── redis-backup.rdb     # Redis snapshot
└── ...
```

### Manual Restore

```bash
# SSH to server
ssh deploy@prod.neapay.com
cd /opt/neapay-complete

# Restore PostgreSQL
docker compose exec -T postgres psql -U neapay < /opt/neapay-backups/20240115_143022/postgres-backup.sql

# Restore Redis
docker compose cp /opt/neapay-backups/20240115_143022/redis-backup.rdb redis:/data/dump.rdb
docker compose exec redis redis-cli BGSAVE

# Restart services
docker compose restart
```

## Kubernetes Deployment

### Prerequisites

```bash
kubectl config use-context <cluster-name>
```

### Deploy

```bash
# Deploy to default namespace
./k8s/deploy.sh

# Deploy to custom namespace
./k8s/deploy.sh my-namespace

# Or use CLI
./deploy-cli.sh k8s-deploy neapay
```

### Update Secrets

```bash
kubectl edit secret neapay-secrets -n neapay

# Edit database-url, redis-url, api-key, api-secret
```

### Access Services

```bash
# Frontend
kubectl port-forward -n neapay svc/neapay-frontend 8080:80

# API
kubectl port-forward -n neapay svc/neapay-api 3000:80

# Prometheus
kubectl port-forward -n neapay deployment/prometheus 9090:9090
```

### Scale Services

```bash
kubectl scale deployment neapay-api -n neapay --replicas=5
kubectl scale deployment neapay-frontend -n neapay --replicas=3
```

### Check Status

```bash
# Pods
kubectl get pods -n neapay -o wide

# Services
kubectl get svc -n neapay

# Events
kubectl get events -n neapay

# Detailed pod info
kubectl describe pod <pod-name> -n neapay

# Logs
kubectl logs -f <pod-name> -n neapay
```

## Troubleshooting

### Docker Compose Issues

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f [service]

# Restart service
docker compose restart [service]

# Force rebuild
docker compose down -v && docker compose build --no-cache
```

### Health Check Failures

```bash
# Check container logs
docker logs <container_id>

# Test endpoint manually
curl http://localhost:3000/health

# Verify network
docker network inspect unified
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker compose exec postgres pg_isready -U neapay

# View PostgreSQL logs
docker compose logs postgres

# Connect to database
docker compose exec postgres psql -U neapay -d neapay
```

### Out of Disk Space

```bash
# Check disk usage
docker system df

# Clean up
docker system prune -a --volumes
```

## Advanced

### Custom Environment Variables

Create `.env.production`:

```bash
NODE_ENV=production
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
POSTGRES_PASSWORD=secure-password
REDIS_PASSWORD=secure-password
GRAFANA_PASSWORD=secure-password
```

### Custom Domains/SSL

Update docker-compose.production.yml:

```yaml
penthouse-api:
  environment:
    - API_DOMAIN=api.neapay.com
```

Add reverse proxy (nginx) to handle SSL termination.

### Database Migrations

```bash
# Run migrations on Kubernetes
kubectl exec -it deployment/neapay-api -n neapay -- npm run migrate

# On Docker Compose
docker compose exec penthouse-api npm run migrate
```

## Support

- Documentation: https://docs.neapay.com
- GitHub Issues: https://github.com/neapay/neapay-complete/issues
- Slack: #deployment-help channel
