# NeaPay Complete - Deployment Checklist

## Phase 1: Local Setup (Your Machine)

### GitHub Configuration
- [ ] Repository secrets created (`GITHUB-SETUP.md`)
  - [ ] STAGING_HOST
  - [ ] STAGING_USER
  - [ ] STAGING_SSH_KEY
  - [ ] PROD_HOST
  - [ ] PROD_USER
  - [ ] PROD_SSH_KEY
  - [ ] REGISTRY_USERNAME
  - [ ] REGISTRY_PASSWORD
  - [ ] SLACK_WEBHOOK

- [ ] SSH keys generated
  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/id_neapay_staging
  ssh-keygen -t ed25519 -f ~/.ssh/id_neapay_prod
  ```

- [ ] GitHub CLI installed and authenticated
  ```bash
  gh auth login
  ```

## Phase 2: Staging Server Setup

### Prerequisites
- [ ] Ubuntu/Debian 20.04+ server
- [ ] Root or sudo access
- [ ] Static IP address or DNS record
- [ ] SSH key pair for deploy user

### Server Configuration
- [ ] Run server setup script
  ```bash
  # On staging server as root
  sudo bash setup-server.sh staging
  ```

- [ ] Verification
  - [ ] Docker installed: `docker --version`
  - [ ] Docker Compose installed: `docker compose version`
  - [ ] Deploy user created: `id deploy`
  - [ ] Deploy user in docker group: `groups deploy`
  - [ ] Directories created: `ls -la /opt/neapay*`

### SSH Configuration
- [ ] Public key added to authorized_keys
  ```bash
  cat ~/.ssh/id_neapay_staging.pub | ssh deploy@staging.neapay.com "cat >> ~/.ssh/authorized_keys"
  ```

- [ ] Test SSH access
  ```bash
  ssh -i ~/.ssh/id_neapay_staging deploy@staging.neapay.com "whoami"
  ```

### Environment Files
- [ ] `.env.staging` created in `/opt/neapay-complete/`
  - [ ] DATABASE_URL updated
  - [ ] POSTGRES_PASSWORD updated
  - [ ] REDIS_URL updated
  - [ ] REDIS_PASSWORD updated
  - [ ] API_KEY updated
  - [ ] SECRET_KEY updated

- [ ] Permissions set: `chmod 600 .env.staging`

### Initial Deployment
- [ ] Repository cloned
  ```bash
  cd /opt/neapay-complete && git clone <repo> .
  ```

- [ ] Images pulled
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.staging.yml pull
  ```

- [ ] Services started
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
  ```

- [ ] Services verified
  ```bash
  docker compose ps
  curl http://localhost:3000/health
  curl http://localhost:5173
  ```

## Phase 3: Production Server Setup

### Prerequisites
- [ ] Ubuntu/Debian 20.04+ server (different from staging)
- [ ] Root or sudo access
- [ ] Static IP address or DNS record
- [ ] SSH key pair for deploy user

### Server Configuration
- [ ] Run server setup script
  ```bash
  # On production server as root
  sudo bash setup-server.sh production
  ```

- [ ] Verification
  - [ ] Docker installed
  - [ ] Docker Compose installed
  - [ ] Deploy user created
  - [ ] Firewall configured (UFW)
  - [ ] Directories created

### SSH Configuration
- [ ] Public key added to authorized_keys
  ```bash
  cat ~/.ssh/id_neapay_prod.pub | ssh deploy@api.neapay.com "cat >> ~/.ssh/authorized_keys"
  ```

- [ ] Test SSH access
  ```bash
  ssh -i ~/.ssh/id_neapay_prod deploy@api.neapay.com "whoami"
  ```

### Environment Files
- [ ] `.env.production` created in `/opt/neapay-complete/`
  - [ ] DATABASE_URL with secure password
  - [ ] POSTGRES_PASSWORD with secure password
  - [ ] REDIS_URL with secure password
  - [ ] REDIS_PASSWORD with secure password
  - [ ] API_KEY generated securely
  - [ ] SECRET_KEY generated securely
  - [ ] GRAFANA_PASSWORD set

- [ ] Permissions set: `chmod 600 .env.production`

### SSL/TLS Setup
- [ ] Nginx installed
  ```bash
  sudo apt-get install -y nginx certbot python3-certbot-nginx
  ```

- [ ] Nginx reverse proxy configured (`SSL-SETUP.md`)
  - [ ] Config created in `/etc/nginx/sites-available/neapay`
  - [ ] Symlink created in `/etc/nginx/sites-enabled/`
  - [ ] Config tested: `sudo nginx -t`

- [ ] SSL certificate issued
  ```bash
  sudo certbot certonly --nginx -d api.neapay.com
  ```

- [ ] Nginx HTTPS config updated
  - [ ] HTTP redirect to HTTPS
  - [ ] SSL certificate paths set
  - [ ] Security headers added
  - [ ] Nginx reloaded

- [ ] Test HTTPS access
  ```bash
  curl https://api.neapay.com
  ```

### Initial Deployment
- [ ] Repository cloned
- [ ] Images pulled
- [ ] Services started with production config
- [ ] Services verified

## Phase 4: Backup Configuration

### PostgreSQL Backups
- [ ] Backup script created: `/opt/neapay-backups/backup.sh`
- [ ] Script made executable
- [ ] Cron job added for daily backups at 2 AM
- [ ] Test backup run: `/opt/neapay-backups/backup.sh`

### S3 Cloud Backups
- [ ] AWS CLI installed
- [ ] AWS credentials configured
- [ ] S3 bucket created: `neapay-backups`
- [ ] S3 backup script created
- [ ] Cron job added for weekly S3 backups
- [ ] S3 lifecycle policy configured

### Backup Verification
- [ ] Manual restore test performed
- [ ] Monthly automated test scheduled
- [ ] Monitoring/alerts configured

## Phase 5: DNS & Domain Setup

### Staging Domain
- [ ] DNS A record created
  ```
  staging.neapay.com → <staging-ip>
  ```

- [ ] DNS propagation verified
  ```bash
  nslookup staging.neapay.com
  ```

### Production Domain
- [ ] DNS A record created
  ```
  api.neapay.com → <production-ip>
  ```

- [ ] DNS TTL set appropriately (3600 or higher)
- [ ] DNS propagation verified

### SSL Certificates
- [ ] Staging cert issued (Let's Encrypt)
- [ ] Production cert issued (Let's Encrypt)
- [ ] Auto-renewal configured

## Phase 6: Monitoring & Logging

### Prometheus
- [ ] Configuration file created: `config/prometheus.yml`
- [ ] Scrape targets verified
- [ ] Prometheus accessible on port 9090

### Grafana
- [ ] Admin password set in `.env.production`
- [ ] Grafana accessible on port 3001
- [ ] Prometheus data source added
- [ ] Dashboards configured
  - [ ] CPU/Memory usage
  - [ ] Request rates
  - [ ] Error rates
  - [ ] Database performance

### Logs
- [ ] Log directories created
- [ ] Log rotation configured
- [ ] Log aggregation considered (ELK, Datadog, etc.)

## Phase 7: GitHub Actions Testing

### Trigger First Build
- [ ] Commit to develop branch
  ```bash
  git commit --allow-empty -m "Test CI/CD pipeline"
  git push origin develop
  ```

- [ ] Monitor workflow
  - [ ] GitHub → Actions → View "Build & Test"
  - [ ] Verify build succeeds
  - [ ] Verify images pushed to GHCR

### Deploy to Staging
- [ ] Staging deployment triggered automatically
  - [ ] SSH connection successful
  - [ ] Code pulled
  - [ ] Images pulled
  - [ ] Services started
  - [ ] Health checks passed
  - [ ] Slack notification received

- [ ] Manual verification
  ```bash
  curl https://staging.neapay.com
  curl https://staging.neapay.com/api/health
  ```

### Test Production Deployment
- [ ] Commit to main branch
  ```bash
  git commit --allow-empty -m "Test production CI/CD"
  git push origin main
  ```

- [ ] Production deployment triggered
  - [ ] Backup created
  - [ ] Blue-green deployment executed
  - [ ] Health checks passed
  - [ ] Slack notification received

- [ ] Manual verification
  ```bash
  curl https://api.neapay.com
  curl https://api.neapay.com/health
  ```

## Phase 8: Kubernetes Setup (Optional)

- [ ] Kubernetes cluster available
- [ ] kubectl configured
- [ ] Secrets updated: `kubectl edit secret neapay-secrets -n neapay`
- [ ] Deployment applied: `kubectl apply -f k8s/`
- [ ] Services verified: `kubectl get svc -n neapay`
- [ ] Pods running: `kubectl get pods -n neapay`

## Phase 9: Documentation & Handoff

- [ ] DEPLOYMENT.md reviewed with team
- [ ] GITHUB-SETUP.md reviewed with team
- [ ] SSL-SETUP.md reviewed with team
- [ ] BACKUP-STRATEGY.md reviewed with team
- [ ] Runbooks created for common operations
  - [ ] How to manually deploy
  - [ ] How to rollback
  - [ ] How to restore from backup
  - [ ] How to scale services
  - [ ] How to troubleshoot

- [ ] Team trained on:
  - [ ] Deployment process
  - [ ] Monitoring dashboards
  - [ ] Alert handling
  - [ ] Backup/restore procedures
  - [ ] Incident response

## Phase 10: Post-Deployment Verification

### Performance
- [ ] Response times acceptable
- [ ] CPU/Memory usage normal
- [ ] Database queries optimized
- [ ] No errors in logs

### Security
- [ ] SSL certificate valid
- [ ] Firewall rules correct
- [ ] Network policies applied (K8s)
- [ ] Secrets not in logs
- [ ] No exposed credentials

### Reliability
- [ ] Services restart on failure
- [ ] Health checks functional
- [ ] Backups running successfully
- [ ] Monitoring alerts working
- [ ] Logs being collected

### Cost
- [ ] Resource requests/limits appropriate
- [ ] Auto-scaling configured correctly
- [ ] Storage usage within budget
- [ ] Backup costs acceptable

## Daily Operations Checklist

- [ ] Check deployment status
  ```bash
  docker compose ps
  ```

- [ ] Review logs
  ```bash
  docker compose logs -f
  ```

- [ ] Monitor metrics
  ```
  http://api.neapay.com:9090 (Prometheus)
  http://api.neapay.com:3001 (Grafana)
  ```

- [ ] Verify backups
  ```bash
  ls -lh /opt/neapay-backups/postgres-backup-*.sql.gz | head -1
  ```

- [ ] Check SSL certificate expiration
  ```bash
  sudo certbot certificates
  ```

- [ ] Review system resources
  ```bash
  df -h              # Disk space
  free -h            # Memory
  top -b -n 1        # CPU
  ```

## Emergency Contacts & Escalation

- [ ] On-call schedule defined
- [ ] Incident channels configured (Slack #incidents)
- [ ] Escalation procedure documented
- [ ] Backup contacts listed

## Sign-Off

- [ ] DevOps Lead: _________________ Date: _______
- [ ] Engineering Manager: _________________ Date: _______
- [ ] Product Manager: _________________ Date: _______

---

**Last Updated:** [DATE]
**Deployment Status:** [STAGING ✅ / PRODUCTION ⏳]
**Issues Outstanding:** None / [LIST]
