#!/usr/bin/env bash
# Deploy script for NeaPay Complete
# Supports blue-green deployments with automatic rollback

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-staging}
BACKUP_DIR="/opt/neapay-backups/$(date +%Y%m%d_%H%M%S)"
APP_DIR="/opt/neapay-complete"
MAX_RETRIES=5
HEALTH_CHECK_INTERVAL=5

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

backup_current_state() {
    log_info "Backing up current deployment..."
    
    mkdir -p "$BACKUP_DIR"
    cd "$APP_DIR"
    
    # Backup running services info
    docker compose images > "$BACKUP_DIR/images.txt" 2>/dev/null || true
    docker compose ps > "$BACKUP_DIR/services.txt" 2>/dev/null || true
    
    # Backup database
    if docker compose ps postgres 2>/dev/null | grep -q Up; then
        log_info "Backing up PostgreSQL..."
        docker compose exec -T postgres pg_dump -U neapay neapay > "$BACKUP_DIR/postgres-backup.sql" 2>/dev/null || true
    fi
    
    # Backup Redis
    if docker compose ps redis 2>/dev/null | grep -q Up; then
        log_info "Backing up Redis..."
        docker compose exec -T redis redis-cli --rdb /data/backup.rdb 2>/dev/null || true
        docker compose exec -T redis cat /data/dump.rdb > "$BACKUP_DIR/redis-backup.rdb" 2>/dev/null || true
    fi
    
    log_success "Backup saved to $BACKUP_DIR"
}

pull_latest_code() {
    log_info "Pulling latest code..."
    cd "$APP_DIR"
    git fetch origin
    git pull origin "$(git rev-parse --abbrev-ref HEAD)"
    log_success "Code updated"
}

pull_latest_images() {
    log_info "Pulling latest Docker images..."
    cd "$APP_DIR"
    docker compose pull --quiet
    log_success "Images pulled"
}

health_check_api() {
    local retries=0
    local url="http://localhost:3000/health"
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            log_success "API is healthy"
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $MAX_RETRIES ]; then
            log_warning "Health check attempt $retries/$MAX_RETRIES failed, retrying in ${HEALTH_CHECK_INTERVAL}s..."
            sleep $HEALTH_CHECK_INTERVAL
        fi
    done
    
    log_error "API health check failed after $MAX_RETRIES attempts"
    return 1
}

health_check_frontend() {
    local retries=0
    local url="http://localhost:5173"
    
    while [ $retries -lt $MAX_RETRIES ]; do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [ "$STATUS" = "200" ]; then
            log_success "Frontend is accessible"
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $MAX_RETRIES ]; then
            log_warning "Frontend check attempt $retries/$MAX_RETRIES failed ($STATUS), retrying..."
            sleep $HEALTH_CHECK_INTERVAL
        fi
    done
    
    log_error "Frontend health check failed"
    return 1
}

deploy_staging() {
    log_info "Deploying to STAGING..."
    
    backup_current_state
    pull_latest_code
    pull_latest_images
    
    log_info "Starting deployment..."
    cd "$APP_DIR"
    docker compose -f docker-compose.yml -f docker-compose.staging.yml down || true
    docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
    
    sleep 5
    
    # Health checks
    if health_check_api && health_check_frontend; then
        log_success "Staging deployment successful"
        
        # Display status
        echo ""
        log_info "Service status:"
        docker compose ps
        
        return 0
    else
        log_error "Staging deployment failed health checks"
        docker compose -f docker-compose.yml -f docker-compose.staging.yml down
        return 1
    fi
}

deploy_production() {
    log_info "Deploying to PRODUCTION (Blue-Green)..."
    
    backup_current_state
    pull_latest_code
    pull_latest_images
    
    log_info "Starting blue-green deployment..."
    cd "$APP_DIR"
    
    # Start new services
    docker compose -f docker-compose.yml -f docker-compose.production.yml up -d
    
    log_info "Waiting for new services to stabilize..."
    sleep 10
    
    # Health checks
    if health_check_api && health_check_frontend; then
        log_success "Production deployment successful"
        
        # Display status
        echo ""
        log_info "Service status:"
        docker compose ps
        
        # Clean up old containers
        log_info "Cleaning up dangling resources..."
        docker container prune -f > /dev/null || true
        
        return 0
    else
        log_error "Production deployment failed health checks - ROLLING BACK"
        
        log_info "Restoring from backup..."
        docker compose -f docker-compose.yml -f docker-compose.production.yml down || true
        
        if [ -f "$BACKUP_DIR/postgres-backup.sql" ]; then
            log_info "Restoring PostgreSQL..."
            docker compose -f docker-compose.yml -f docker-compose.production.yml up -d postgres
            sleep 5
            docker compose exec -T postgres psql -U neapay < "$BACKUP_DIR/postgres-backup.sql" 2>/dev/null || true
        fi
        
        docker compose -f docker-compose.yml -f docker-compose.production.yml up -d
        
        return 1
    fi
}

cleanup_backups() {
    log_info "Cleaning up old backups (keeping last 5)..."
    cd /opt/neapay-backups
    ls -t -d */ | tail -n +6 | xargs -r rm -rf
    log_success "Cleanup complete"
}

main() {
    log_info "NeaPay Complete Deployment Script"
    echo ""
    
    case "${ENVIRONMENT}" in
        staging)
            deploy_staging || exit 1
            ;;
        production)
            deploy_production || exit 1
            cleanup_backups
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            echo "Usage: $0 {staging|production}"
            exit 1
            ;;
    esac
    
    echo ""
    log_success "Deployment pipeline completed successfully"
}

main "$@"
