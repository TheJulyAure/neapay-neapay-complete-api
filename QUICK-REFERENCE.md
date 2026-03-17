# NeaPay Complete - Quick Reference Guide

## 🚀 Quick Start

```bash
# Option 1: Interactive menu
bash quickstart.sh

# Option 2: Implementation wizard
bash IMPLEMENTATION.sh

# Option 3: Command line
./deploy-cli.sh help
```

## 📋 Deployment Commands

### Local Development

```bash
# Build images
./deploy-cli.sh build

# Test locally
./deploy-cli.sh test

# Start staging locally
./deploy-cli.sh staging-up
./deploy-cli.sh staging-logs
./deploy-cli.sh staging-down
```

### Staging Deployment

```bash
# Auto-deploys on develop branch push
git push origin develop

# Manual trigger
./deploy-cli.sh deploy-staging
```

### Production Deployment

```bash
# Auto-deploys on main branch push
git push origin main

# Or with tags (recommended)
git tag v1.0.0
git push origin main --tags
```

### View Status

```bash
# Check services
docker compose ps

# View logs
docker compose logs -f [service]

# Health check
curl http://localhost:3000/health
curl http://localhost:5173

# Monitoring
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3001
```

## 🔐 Server Access

### SSH into Servers

```bash
# Staging
ssh -i ~/.ssh/id_neapay_staging deploy@staging.neapay.com

# Production
ssh -i ~/.ssh/id_neapay_prod deploy@api.neapay.com
```

### View Remote Logs

```bash
# On server
docker compose logs -f [service]

# Or remotely
ssh deploy@staging.neapay.com "cd /opt/neapay-complete && docker compose logs -f api"
```

### Manual Remote Deployment

```bash
# SSH to server
ssh deploy@staging.neapay.com

# Pull latest
cd /opt/neapay-complete
git pull origin develop

# Deploy
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d

# Verify
docker compose ps
curl http://localhost:3000/health
```

## 📊 Monitoring

### Check Service Health

```bash
# All at once
docker compose ps

# Per service
docker compose exec api curl http://localhost:3000/health
docker compose exec postgres pg_isready -U neapay
docker compose exec redis redis-cli ping

# View resource usage
docker stats
```

### View Metrics

- **Prometheus**: http://localhost:9090 (raw metrics)
- **Grafana**: http://localhost:3001 (dashboards)

### Common Logs to Check

```bash
# Application logs
docker compose logs -f api

# Database logs
docker compose logs -f postgres

# Frontend logs
docker compose logs -f frontend

# Last 100 lines
docker compose logs --tail 100 api
```

## 💾 Backup Operations

### Manual Backup

```bash
# SSH to server
ssh deploy@production.neapay.com

# Create backup
/opt/neapay-backups/backup.sh

# List backups
ls -lh /opt/neapay-backups/postgres-backup-*.sql.gz
```

### Restore from Backup

```bash
# SSH to server
ssh deploy@production.neapay.com
cd /opt/neapay-complete

# Stop services
docker compose down

# Restore database
BACKUP_FILE="/opt/neapay-backups/postgres-backup-20240115_020000.sql.gz"
gunzip < "$BACKUP_FILE" | docker compose exec -T postgres psql -U neapay

# Start services
docker compose up -d
```

## 🔄 Rollback

### Automatic Rollback

If production health checks fail, GitHub Actions automatically:
1. Stops failed deployment
2. Creates rollback instructions
3. Notifies Slack

### Manual Rollback

```bash
# SSH to production
ssh deploy@api.neapay.com
cd /opt/neapay-complete

# Restore from backup
git pull origin main  # Get latest code
docker compose -f docker-compose.yml -f docker-compose.production.yml pull
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d

# If database is corrupted
BACKUP="/opt/neapay-backups/postgres-backup-LATEST.sql.gz"
gunzip < "$BACKUP" | docker compose exec -T postgres psql -U neapay
docker compose restart
```

## 🆘 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs api

# Common issues:
# - Port already in use: docker compose down && docker compose up -d
# - Database not ready: docker compose restart postgres
# - Memory limit: increase in docker-compose file
```

### Health Check Failing

```bash
# Check endpoint
curl -v http://localhost:3000/health

# Check service logs
docker compose logs -f api

# Check network
docker network inspect unified

# Restart service
docker compose restart api
```

### Database Connection Error

```bash
# Check PostgreSQL is running
docker compose ps postgres

# Check connection
docker compose exec postgres psql -U neapay -c "SELECT 1;"

# Check environment variables
docker compose exec api env | grep DATABASE_URL

# Verify credentials in .env
cat /opt/neapay-complete/.env.production
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a --volumes

# Remove old backups
ls -lh /opt/neapay-backups/ | tail -20
rm /opt/neapay-backups/postgres-backup-OLD_DATE.sql.gz

# Check log file sizes
du -sh /opt/neapay-complete/logs/
```

### SSH Connection Issues

```bash
# Verify key exists
ls -la ~/.ssh/id_neapay_staging

# Test connection
ssh -v -i ~/.ssh/id_neapay_staging deploy@staging.neapay.com

# If key permission error
chmod 600 ~/.ssh/id_neapay_*

# If connection refused
# Check: IP, firewall, SSH enabled on server
ssh deploy@staging.neapay.com "systemctl status ssh"
```

## 📝 GitHub Actions

### View Workflow Status

- Navigate to: https://github.com/your-org/neapay-complete/actions
- Click workflow name
- See build logs, deployment status, and notifications

### Common Workflow Issues

```bash
# Secrets not set
# Solution: GitHub → Settings → Secrets and variables → Actions

# Build fails
# Check: Code changes don't have syntax errors
# Review: Logs in GitHub Actions

# Deployment fails
# Check: SSH keys work (ssh -i key user@host)
# Check: Server directories exist (/opt/neapay-complete)
# Review: Slack notification for error details
```

## 🔑 Working with Secrets

### Update Secret Values

```bash
# Via GitHub CLI
gh secret set SECRET_NAME --body "new-value"

# View secrets list
gh secret list

# Delete secret
gh secret delete SECRET_NAME
```

### Emergency: Clear All Secrets

```bash
# This should be rare, only in security breach scenarios
gh secret list | awk '{print $1}' | xargs -I {} gh secret delete {}
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| DEPLOYMENT.md | Complete deployment guide |
| GITHUB-SETUP.md | GitHub secrets and workflow setup |
| SSL-SETUP.md | HTTPS and nginx configuration |
| BACKUP-STRATEGY.md | Database backup and recovery |
| DEPLOYMENT-CHECKLIST.md | Step-by-step verification |
| quickstart.sh | Interactive setup wizard |
| deploy-cli.sh | Command-line deployment interface |

## 🎯 Typical Workflow

```bash
# 1. Develop locally
git checkout -b feature/new-feature
# Make changes...
git add .
git commit -m "Add new feature"

# 2. Test locally
./deploy-cli.sh build
./deploy-cli.sh staging-up
# Manual testing...
./deploy-cli.sh staging-down

# 3. Push to staging
git push origin feature/new-feature
# Creates Pull Request
# GitHub Actions runs tests

# 4. Merge to develop
# Staging deployment triggered automatically

# 5. Verify staging
curl https://staging.neapay.com
# Test all features...

# 6. Release to production
git merge develop
git push origin main
git tag v1.1.0
git push origin main --tags
# Production deployment triggered automatically

# 7. Monitor
# Check Grafana dashboards
# Review logs in Prometheus
# Verify Slack notifications
```

## 🚨 Incident Response

### Service Down

1. Check status: `docker compose ps`
2. View logs: `docker compose logs -f [service]`
3. Restart: `docker compose restart [service]`
4. If persists: Check database, check disk space, check memory
5. Last resort: Rollback using previous backup

### Database Corruption

1. Stop services: `docker compose down`
2. List backups: `ls /opt/neapay-backups/`
3. Restore: `gunzip < backup.sql.gz | docker compose exec -T postgres psql -U neapay`
4. Start services: `docker compose up -d`

### Security Breach

1. Immediately rotate credentials (SSH keys, API keys)
2. Update GitHub secrets
3. Review deploy logs for unauthorized access
4. Backup current state for forensics
5. Redeploy from known-good backup
6. Notify team and stakeholders

## 💡 Best Practices

✅ Always test on staging before production
✅ Use semantic versioning for tags (v1.0.0)
✅ Keep environment files secure (chmod 600)
✅ Review logs before and after deployment
✅ Test backups monthly (automated)
✅ Document any manual changes
✅ Keep SSH keys safe and rotate regularly
✅ Monitor resource usage proactively

---

**Last Updated:** 2024-01-15
**For detailed info:** See DEPLOYMENT.md
