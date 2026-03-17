#!/usr/bin/env bash
# Server Setup Script - Run this on staging and production servers
# Usage: ./setup-server.sh [staging|production]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

ENVIRONMENT=${1:-staging}
APP_DIR="/opt/neapay-complete"
BACKUP_DIR="/opt/neapay-backups"
DEPLOY_USER="deploy"

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Usage: $0 [staging|production]"
    exit 1
fi

log_info "Setting up $ENVIRONMENT server"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi

# Step 1: Update system
log_info "Updating system packages..."
apt-get update -y
apt-get upgrade -y
log_success "System updated"

# Step 2: Install Docker
log_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    log_success "Docker installed"
else
    log_success "Docker already installed: $(docker --version)"
fi

# Step 3: Install Docker Compose
log_info "Checking Docker Compose installation..."
if ! command -v docker compose &> /dev/null; then
    log_info "Installing Docker Compose..."
    apt-get install -y docker-compose-plugin
    log_success "Docker Compose installed"
else
    log_success "Docker Compose already installed"
fi

# Step 4: Install git
log_info "Checking git installation..."
if ! command -v git &> /dev/null; then
    log_info "Installing git..."
    apt-get install -y git
    log_success "git installed"
else
    log_success "git already installed"
fi

# Step 5: Create deploy user
log_info "Setting up deploy user..."
if id "$DEPLOY_USER" &>/dev/null; then
    log_success "User $DEPLOY_USER already exists"
else
    useradd -m -s /bin/bash "$DEPLOY_USER"
    log_success "Created user $DEPLOY_USER"
fi

# Add user to docker group
usermod -aG docker "$DEPLOY_USER"
log_success "Added $DEPLOY_USER to docker group"

# Step 6: Create directories
log_info "Creating application directories..."
mkdir -p "$APP_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$APP_DIR/logs/api"
mkdir -p "$APP_DIR/logs/frontend"

chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$BACKUP_DIR"
chmod 755 "$APP_DIR"
chmod 755 "$BACKUP_DIR"

log_success "Directories created"

# Step 7: SSH key directory
log_info "Setting up SSH for deploy user..."
sudo -u "$DEPLOY_USER" mkdir -p "/home/$DEPLOY_USER/.ssh"
sudo -u "$DEPLOY_USER" chmod 700 "/home/$DEPLOY_USER/.ssh"
log_success "SSH directory ready"

# Step 8: Docker daemon configuration
log_info "Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl restart docker
log_success "Docker configured"

# Step 9: Create systemd service for monitoring
log_info "Setting up systemd service..."
cat > /etc/systemd/system/neapay.service << EOF
[Unit]
Description=NeaPay Complete Application
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/docker compose -f docker-compose.yml -f docker-compose.$ENVIRONMENT.yml up
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable neapay.service
log_success "Systemd service created"

# Step 10: Setup log rotation
log_info "Setting up log rotation..."
cat > /etc/logrotate.d/neapay << 'EOF'
/opt/neapay-complete/logs/*/*.log {
  daily
  rotate 7
  compress
  delaycompress
  missingok
  notifempty
  create 0640 deploy deploy
  sharedscripts
}
EOF
log_success "Log rotation configured"

# Step 11: Environment-specific setup
if [ "$ENVIRONMENT" = "production" ]; then
    log_info "Configuring production-specific settings..."
    
    # Install monitoring tools
    apt-get install -y htop iotop curl wget
    
    # Set up firewall (UFW)
    apt-get install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw enable
    
    log_success "Production settings configured"
fi

# Step 12: Create initial .env file
log_info "Creating environment file template..."
cat > "$APP_DIR/.env.$ENVIRONMENT" << EOF
# NeaPay Complete - $ENVIRONMENT Environment
# Last updated: $(date)

# Node Environment
NODE_ENV=$ENVIRONMENT
PORT=3000
LOG_LEVEL=$([ "$ENVIRONMENT" = "production" ] && echo "info" || echo "debug")

# Database
DATABASE_URL=postgresql://neapay:CHANGE_ME@localhost:5432/neapay
POSTGRES_PASSWORD=CHANGE_ME

# Redis
REDIS_URL=redis://:CHANGE_ME@localhost:6379
REDIS_PASSWORD=CHANGE_ME

# API Configuration
API_KEY=CHANGE_ME
SECRET_KEY=CHANGE_ME

# Frontend
VITE_API_URL=$([ "$ENVIRONMENT" = "production" ] && echo "https://api.neapay.com" || echo "http://localhost:3000")
VITE_ENV=$ENVIRONMENT

# Monitoring (production only)
$([ "$ENVIRONMENT" = "production" ] && echo "GRAFANA_PASSWORD=CHANGE_ME" || echo "# GRAFANA_PASSWORD not needed in staging")
EOF

chown "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR/.env.$ENVIRONMENT"
chmod 600 "$APP_DIR/.env.$ENVIRONMENT"

log_warning "⚠️  Update .env.$ENVIRONMENT with actual values"
log_warning "    nano $APP_DIR/.env.$ENVIRONMENT"

# Step 13: Create deployment instructions file
cat > "$APP_DIR/DEPLOY-NOTES.txt" << 'EOF'
NeaPay Complete - Server Setup Complete
========================================

Environment Configuration:
1. Edit .env file with actual values:
   - DATABASE_URL and POSTGRES_PASSWORD
   - REDIS_URL and REDIS_PASSWORD
   - API_KEY and SECRET_KEY

2. Update authorized_keys for GitHub Actions:
   cat ~/.ssh/authorized_keys

3. First deployment:
   git clone <repo-url> .
   docker compose pull
   docker compose up -d

4. Check status:
   docker compose ps
   docker compose logs -f

5. Backup location:
   /opt/neapay-backups/

6. View service status:
   systemctl status neapay
   journalctl -fu neapay

EOF

chown "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR/DEPLOY-NOTES.txt"

# Step 14: System information
echo ""
log_info "System Information:"
echo "  Environment: $ENVIRONMENT"
echo "  App Directory: $APP_DIR"
echo "  Backup Directory: $BACKUP_DIR"
echo "  Deploy User: $DEPLOY_USER"
echo "  Docker Version: $(docker --version)"
echo "  Docker Compose: $(docker compose version)"
echo "  Kernel: $(uname -r)"
echo "  Memory: $(free -h | awk 'NR==2 {print $2}')"
echo "  Disk: $(df -h / | awk 'NR==2 {print $2}')"

echo ""
log_success "Server setup complete!"

echo ""
log_info "Next Steps:"
echo "  1. Switch to deploy user: sudo su - $DEPLOY_USER"
echo "  2. Add SSH public key to ~/.ssh/authorized_keys"
echo "  3. Update .env file with real values"
echo "  4. Clone repository: cd $APP_DIR && git clone <repo> ."
echo "  5. Test deployment: docker compose up -d"
echo ""
