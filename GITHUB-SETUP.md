# GitHub Actions Secrets Setup Guide

This guide walks through setting up all required GitHub secrets for the CI/CD pipeline.

## Prerequisites

- GitHub repository with admin access
- SSH keys for staging and production servers
- Slack webhook URL (optional but recommended)

## Step 1: Generate SSH Keys

If you don't have SSH keys, generate them:

```bash
# Generate staging key
ssh-keygen -t ed25519 -f ~/.ssh/id_neapay_staging -C "neapay-staging-deploy"
# Press Enter for empty passphrase

# Generate production key
ssh-keygen -t ed25519 -f ~/.ssh/id_neapay_prod -C "neapay-prod-deploy"
# Press Enter for empty passphrase
```

This creates:
- `~/.ssh/id_neapay_staging` (private key)
- `~/.ssh/id_neapay_staging.pub` (public key)
- `~/.ssh/id_neapay_prod` (private key)
- `~/.ssh/id_neapay_prod.pub` (public key)

## Step 2: Configure Server Access

### On Staging Server

```bash
# SSH into staging server
ssh deploy@staging.neapay.com

# Create .ssh directory if needed
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key
echo "$(cat ~/.ssh/id_neapay_staging.pub)" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### On Production Server

```bash
# SSH into production server
ssh deploy@api.neapay.com

# Create .ssh directory if needed
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key
echo "$(cat ~/.ssh/id_neapay_prod.pub)" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## Step 3: Prepare Servers

### Create Application Directories

```bash
# On BOTH staging and production servers:

# Create app directory
sudo mkdir -p /opt/neapay-complete
sudo chown deploy:deploy /opt/neapay-complete
chmod 755 /opt/neapay-complete

# Create backup directory
sudo mkdir -p /opt/neapay-backups
sudo chown deploy:deploy /opt/neapay-backups
chmod 755 /opt/neapay-backups

# Create logs directory
mkdir -p /opt/neapay-complete/logs/{api,frontend}
chmod 755 /opt/neapay-complete/logs/{api,frontend}

# Clone repository (or initial deployment will do this)
cd /opt/neapay-complete
git clone https://github.com/your-org/neapay-complete.git .
```

### Install Docker and Docker Compose

```bash
# Ubuntu/Debian example:
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker deploy

# Verify installation
docker --version
docker compose version
```

## Step 4: Set GitHub Repository Secrets

1. Go to: **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add each secret below:

### Staging Secrets

**STAGING_HOST**
```
staging.neapay.com
```

**STAGING_USER**
```
deploy
```

**STAGING_SSH_KEY**
```
# Copy the FULL content of ~/.ssh/id_neapay_staging (private key)
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

### Production Secrets

**PROD_HOST**
```
api.neapay.com
```

**PROD_USER**
```
deploy
```

**PROD_SSH_KEY**
```
# Copy the FULL content of ~/.ssh/id_neapay_prod (private key)
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

### Container Registry

**REGISTRY_USERNAME**
```
your-github-username
```

**REGISTRY_PASSWORD**
```
# GitHub Personal Access Token with 'read:packages' scope
# Create at: https://github.com/settings/tokens
ghp_xxxxxxxxxxxxxxxxxxxx
```

### Slack Notifications (Optional)

**SLACK_WEBHOOK**
```
# Create at: https://api.slack.com/apps
https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## Step 5: Verify Secrets are Set

```bash
# List all secrets (doesn't show values)
gh secret list
```

## Step 6: Create Environment Files

### Create .env.staging

```bash
# On staging server
cd /opt/neapay-complete
cat > .env.staging << 'EOF'
# Node Environment
NODE_ENV=staging
PORT=3000
LOG_LEVEL=debug

# Database
DATABASE_URL=postgresql://neapay:change-me-staging@localhost:5432/neapay
POSTGRES_PASSWORD=change-me-staging

# Redis
REDIS_URL=redis://:change-me-staging@localhost:6379
REDIS_PASSWORD=change-me-staging

# API Configuration
API_KEY=staging-key-change-me
SECRET_KEY=staging-secret-change-me

# Frontend
VITE_API_URL=http://localhost:3000
VITE_ENV=staging
EOF
```

### Create .env.production

```bash
# On production server
cd /opt/neapay-complete
cat > .env.production << 'EOF'
# Node Environment
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database (use managed DB or strong password)
DATABASE_URL=postgresql://neapay:CHANGE_ME_SECURE_PASSWORD@localhost:5432/neapay
POSTGRES_PASSWORD=CHANGE_ME_SECURE_PASSWORD

# Redis (use managed Redis or strong password)
REDIS_URL=redis://:CHANGE_ME_SECURE_PASSWORD@localhost:6379
REDIS_PASSWORD=CHANGE_ME_SECURE_PASSWORD

# API Configuration (generate secure keys)
API_KEY=prod-key-CHANGE_ME_GENERATE_SECURE
SECRET_KEY=prod-secret-CHANGE_ME_GENERATE_SECURE

# Frontend
VITE_API_URL=https://api.neapay.com
VITE_ENV=production

# Monitoring
GRAFANA_PASSWORD=CHANGE_ME_SECURE_PASSWORD
EOF

# Restrict permissions
chmod 600 .env.production
```

## Step 7: Test SSH Access

Verify GitHub Actions can connect:

```bash
# From your local machine, test the connection
ssh -i ~/.ssh/id_neapay_staging deploy@staging.neapay.com "echo 'Staging SSH OK'"
ssh -i ~/.ssh/id_neapay_prod deploy@api.neapay.com "echo 'Production SSH OK'"
```

## Step 8: Configure Slack Webhook (Optional)

1. Go to https://api.slack.com/apps
2. Click **Create New App**
3. Choose **From scratch**
4. Enter app name: "NeaPay Deployer"
5. Select your workspace
6. Go to **Incoming Webhooks**
7. Click **Add New Webhook to Workspace**
8. Select a channel (e.g., #deployments)
9. Copy the webhook URL
10. Add as `SLACK_WEBHOOK` secret in GitHub

## Step 9: Test Initial Deployment

```bash
# Push a commit to develop branch
git checkout develop
git commit --allow-empty -m "Test staging deployment"
git push origin develop

# Monitor the workflow:
# GitHub → Actions → See the "Deploy to Staging" workflow run
```

Check the logs in GitHub Actions to confirm:
- ✅ SSH connection successful
- ✅ Code pulled
- ✅ Images pulled
- ✅ Services started
- ✅ Health checks passed
- ✅ Slack notification sent

## Troubleshooting

### SSH Connection Refused

```bash
# Verify public key is on server
ssh deploy@staging.neapay.com "cat ~/.ssh/authorized_keys"

# Regenerate and add key again
cat ~/.ssh/id_neapay_staging.pub | ssh deploy@staging.neapay.com "cat >> ~/.ssh/authorized_keys"
```

### Docker Compose Not Found

```bash
# On server, install Docker Compose
sudo apt-get install -y docker-compose-plugin

# Or use docker-compose (older version)
sudo apt-get install -y docker-compose
```

### Permission Denied on Backup Directory

```bash
# On server
sudo chown -R deploy:deploy /opt/neapay-backups
chmod 755 /opt/neapay-backups
```

### Workflow Fails on Secrets

- Verify secret names match exactly in workflow files
- Re-add secrets if recently created
- Check for leading/trailing whitespace in secret values

## Next Steps

1. Push code to trigger first workflow
2. Monitor deployment in GitHub Actions
3. Verify services are running on servers
4. Set up monitoring dashboards in Grafana
5. Configure SSL/TLS certificates (nginx reverse proxy)
6. Set up database backups (pg_dump scheduled jobs)
7. Configure log aggregation (ELK, Datadog, etc.)
