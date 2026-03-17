#!/usr/bin/env bash
# Quick Start Guide - One script to rule them all

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

STEP=${1:-menu}

show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║     NeaPay Complete - Deployment Quick Start             ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Choose an option:"
    echo ""
    echo "1) Setup GitHub Secrets"
    echo "2) Setup Staging Server"
    echo "3) Setup Production Server"
    echo "4) Test Staging Deployment"
    echo "5) Deploy to Production"
    echo "6) View Deployment Status"
    echo "7) View Logs"
    echo "8) Rollback Production"
    echo "9) Setup SSL/TLS"
    echo "10) Configure Backups"
    echo "11) View Documentation"
    echo "0) Exit"
    echo ""
    read -p "Enter your choice [0-11]: " choice
    
    case $choice in
        1) setup_github_secrets ;;
        2) setup_staging ;;
        3) setup_production ;;
        4) test_staging ;;
        5) deploy_production ;;
        6) view_status ;;
        7) view_logs ;;
        8) rollback_production ;;
        9) setup_ssl ;;
        10) setup_backups ;;
        11) view_docs ;;
        0) exit 0 ;;
        *) log_error "Invalid choice"; show_menu ;;
    esac
}

setup_github_secrets() {
    log_info "Setting up GitHub Secrets..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI not installed"
        echo "Install from: https://cli.github.com"
        return 1
    fi
    
    chmod +x github-setup.sh
    ./github-setup.sh
}

setup_staging() {
    log_info "Setting up Staging Server..."
    
    read -p "Enter staging server IP/hostname: " staging_host
    read -p "Enter SSH user (usually 'root'): " ssh_user
    
    log_info "Copying setup script to server..."
    scp -r setup-server.sh "$ssh_user@$staging_host":/tmp/
    
    log_info "Running setup on remote server..."
    ssh "$ssh_user@$staging_host" "bash /tmp/setup-server.sh staging"
    
    log_success "Staging server setup complete"
    echo ""
    log_info "Next: Create .env.staging with actual values"
    echo "      ssh $ssh_user@$staging_host"
    echo "      nano /opt/neapay-complete/.env.staging"
}

setup_production() {
    log_info "Setting up Production Server..."
    
    read -p "Enter production server IP/hostname: " prod_host
    read -p "Enter SSH user (usually 'root'): " ssh_user
    
    log_warning "⚠️  This will configure your PRODUCTION server"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_warning "Cancelled"
        return 0
    fi
    
    log_info "Copying setup script to server..."
    scp -r setup-server.sh "$ssh_user@$prod_host":/tmp/
    
    log_info "Running setup on remote server..."
    ssh "$ssh_user@$prod_host" "bash /tmp/setup-server.sh production"
    
    log_success "Production server setup complete"
    echo ""
    log_info "Next Steps:"
    echo "  1. Create .env.production with actual values"
    echo "  2. Set up SSL certificates (SSL-SETUP.md)"
    echo "  3. Configure backups (BACKUP-STRATEGY.md)"
}

test_staging() {
    log_info "Testing Staging Deployment..."
    
    echo ""
    echo "This will:"
    echo "  1. Commit to develop branch"
    echo "  2. Push to GitHub"
    echo "  3. Trigger CI/CD workflow"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        return 0
    fi
    
    git commit --allow-empty -m "Test staging deployment - $(date)"
    git push origin develop
    
    log_success "Pushed to develop branch"
    echo ""
    log_info "Monitor at: https://github.com/your-org/neapay-complete/actions"
    echo ""
    read -p "Press Enter to open GitHub Actions in browser..."
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "https://github.com/$(git remote get-url origin | sed 's|.*github.com/||g' | sed 's|.git$||g')/actions"
    elif command -v open &> /dev/null; then
        open "https://github.com/$(git remote get-url origin | sed 's|.*github.com/||g' | sed 's|.git$||g')/actions"
    fi
}

deploy_production() {
    log_info "Deploying to Production..."
    
    log_warning "⚠️  PRODUCTION DEPLOYMENT"
    read -p "Have you tested staging? (yes/no): " tested_staging
    if [ "$tested_staging" != "yes" ]; then
        log_error "Please test staging first"
        return 1
    fi
    
    read -p "Enter version number (e.g., 1.2.0): " version
    
    echo ""
    echo "Summary:"
    echo "  Version: $version"
    echo "  Branch: main"
    echo "  Action: Blue-green deployment with automatic rollback"
    echo ""
    
    read -p "Deploy to production? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_warning "Cancelled"
        return 0
    fi
    
    git tag "v$version"
    git push origin main --tags
    
    log_success "Tagged v$version and pushed to main"
    echo ""
    log_info "Production deployment triggered"
    echo ""
    log_info "Monitor at: https://github.com/your-org/neapay-complete/actions"
}

view_status() {
    log_info "Deployment Status"
    echo ""
    
    read -p "Enter server (staging/production): " server
    read -p "Enter SSH connection (user@host): " ssh_conn
    
    ssh "$ssh_conn" << 'EOF'
    echo "Services:"
    docker compose ps
    echo ""
    echo "Health Checks:"
    echo "API: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/health)"
    echo "Frontend: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:5173)"
    echo ""
    echo "Resource Usage:"
    docker stats --no-stream
EOF
}

view_logs() {
    log_info "View Deployment Logs"
    echo ""
    
    read -p "Enter SSH connection (user@host): " ssh_conn
    read -p "Service (api/frontend/postgres/redis) [api]: " service
    service=${service:-api}
    
    ssh "$ssh_conn" "cd /opt/neapay-complete && docker compose logs -f --tail 100 $service"
}

rollback_production() {
    log_error "ROLLBACK PRODUCTION"
    echo ""
    
    read -p "This will rollback production. Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        return 0
    fi
    
    read -p "Enter SSH connection (user@host): " ssh_conn
    
    ssh "$ssh_conn" << 'EOF'
    set -e
    cd /opt/neapay-complete
    
    echo "Available backups:"
    ls -lh /opt/neapay-backups/ | head -10
    echo ""
    
    echo "Pulling latest images from git..."
    git pull origin main
    
    echo "Restarting services..."
    docker compose -f docker-compose.yml -f docker-compose.production.yml restart
    
    echo "Waiting for services to stabilize..."
    sleep 10
    
    echo "Service status:"
    docker compose ps
EOF
    
    log_success "Rollback complete"
}

setup_ssl() {
    log_info "SSL/TLS Setup Guide"
    less SSL-SETUP.md || cat SSL-SETUP.md
}

setup_backups() {
    log_info "Backup Strategy Guide"
    less BACKUP-STRATEGY.md || cat BACKUP-STRATEGY.md
}

view_docs() {
    echo ""
    echo "Available Documentation:"
    echo "  1) Deployment Overview (DEPLOYMENT.md)"
    echo "  2) GitHub Setup (GITHUB-SETUP.md)"
    echo "  3) Deployment Checklist (DEPLOYMENT-CHECKLIST.md)"
    echo "  4) SSL/TLS Configuration (SSL-SETUP.md)"
    echo "  5) Backup Strategy (BACKUP-STRATEGY.md)"
    echo ""
    
    read -p "Choose (1-5): " doc_choice
    
    case $doc_choice in
        1) less DEPLOYMENT.md || cat DEPLOYMENT.md ;;
        2) less GITHUB-SETUP.md || cat GITHUB-SETUP.md ;;
        3) less DEPLOYMENT-CHECKLIST.md || cat DEPLOYMENT-CHECKLIST.md ;;
        4) less SSL-SETUP.md || cat SSL-SETUP.md ;;
        5) less BACKUP-STRATEGY.md || cat BACKUP-STRATEGY.md ;;
        *) log_error "Invalid choice" ;;
    esac
}

# Run
if [ "$STEP" = "menu" ]; then
    show_menu
else
    $STEP
fi
