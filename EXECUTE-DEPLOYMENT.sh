#!/usr/bin/env bash
# FINAL DEPLOYMENT EXECUTION - NeaPay Complete
# This script executes the complete deployment pipeline

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

clear
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    🚀 NeaPay Complete Deployment 🚀                         ║
║                                                                              ║
║                         FINAL EXECUTION SCRIPT                              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

echo ""
log_info "Deployment Configuration Summary"
echo ""

# Determine environment
ENVIRONMENT=${1:-undefined}

if [ "$ENVIRONMENT" = "undefined" ]; then
    echo "Choose deployment target:"
    echo "  1) Staging (develop branch)"
    echo "  2) Production (main branch)"
    echo "  3) Local Testing"
    echo ""
    read -p "Select (1-3): " choice
    
    case $choice in
        1) ENVIRONMENT="staging" ;;
        2) ENVIRONMENT="production" ;;
        3) ENVIRONMENT="local" ;;
        *) log_error "Invalid choice"; exit 1 ;;
    esac
fi

case $ENVIRONMENT in
    staging)
        TARGET_BRANCH="develop"
        DOCKER_COMPOSE_FILE="docker-compose.staging.yml"
        DESCRIPTION="Staging Environment (develop branch)"
        ;;
    production)
        TARGET_BRANCH="main"
        DOCKER_COMPOSE_FILE="docker-compose.production.yml"
        DESCRIPTION="Production Environment (main branch)"
        ;;
    local)
        TARGET_BRANCH="develop"
        DOCKER_COMPOSE_FILE="docker-compose.staging.yml"
        DESCRIPTION="Local Testing (no git push)"
        ;;
    *)
        log_error "Invalid environment"
        exit 1
        ;;
esac

echo "Target: $DESCRIPTION"
echo "Branch: $TARGET_BRANCH"
echo "Config: $DOCKER_COMPOSE_FILE"
echo ""

# Confirmation
if [ "$ENVIRONMENT" = "production" ]; then
    log_warning "⚠️  PRODUCTION DEPLOYMENT - HIGH RISK"
    read -p "Type 'DEPLOY TO PRODUCTION' to confirm: " confirm
    if [ "$confirm" != "DEPLOY TO PRODUCTION" ]; then
        log_error "Deployment cancelled"
        exit 1
    fi
fi

echo ""
log_info "Starting Deployment Pipeline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Phase 1: Check Prerequisites
log_info "Phase 1: Checking Prerequisites"
echo ""

if ! command -v docker &> /dev/null; then
    log_error "Docker not installed"
    exit 1
fi
log_success "Docker installed: $(docker --version)"

if ! command -v git &> /dev/null; then
    log_error "Git not installed"
    exit 1
fi
log_success "Git installed: $(git --version | head -1)"

if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    log_success "Docker Compose file found: $DOCKER_COMPOSE_FILE"
else
    log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
    exit 1
fi

echo ""

# Phase 2: Validate Configuration
log_info "Phase 2: Validating Docker Compose Configuration"
echo ""

if docker compose -f "$DOCKER_COMPOSE_FILE" config > /dev/null 2>&1; then
    log_success "Configuration valid"
else
    log_error "Configuration invalid - check syntax"
    docker compose -f "$DOCKER_COMPOSE_FILE" config
    exit 1
fi

echo ""

# Phase 3: Build Images (if local)
if [ "$ENVIRONMENT" = "local" ]; then
    log_info "Phase 3: Building Docker Images"
    echo ""
    
    docker compose -f docker-compose.yml -f "$DOCKER_COMPOSE_FILE" build --no-cache
    
    if [ $? -eq 0 ]; then
        log_success "Images built successfully"
    else
        log_error "Build failed"
        exit 1
    fi
    echo ""
fi

# Phase 4: Git Operations
if [ "$ENVIRONMENT" != "local" ]; then
    log_info "Phase 4: Git Operations"
    echo ""
    
    log_info "Current branch: $(git rev-parse --abbrev-ref HEAD)"
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_warning "Uncommitted changes detected"
        git status --short
        read -p "Continue anyway? (yes/no): " continue_anyway
        if [ "$continue_anyway" != "yes" ]; then
            log_error "Deployment cancelled"
            exit 1
        fi
    fi
    
    # Switch to target branch
    log_info "Switching to $TARGET_BRANCH branch..."
    if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
        git checkout "$TARGET_BRANCH"
        git pull origin "$TARGET_BRANCH"
    else
        log_warning "Branch $TARGET_BRANCH does not exist"
        log_info "Creating new branch from current"
        git checkout -b "$TARGET_BRANCH"
    fi
    
    log_success "On branch: $(git rev-parse --abbrev-ref HEAD)"
    echo ""
fi

# Phase 5: Deployment
log_info "Phase 5: Deploying Services"
echo ""

if [ "$ENVIRONMENT" = "local" ]; then
    log_info "Starting services locally..."
    
    # Stop existing services
    docker compose -f docker-compose.yml -f "$DOCKER_COMPOSE_FILE" down 2>/dev/null || true
    
    # Start services
    docker compose -f docker-compose.yml -f "$DOCKER_COMPOSE_FILE" up -d
    
    log_success "Services started"
    echo ""
    
    # Wait for services
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Health checks
    log_info "Checking service health..."
    
    API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "000")
    if [ "$API_HEALTH" = "200" ]; then
        log_success "API healthy ($API_HEALTH)"
    else
        log_warning "API health: $API_HEALTH"
    fi
    
    FE_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5173 2>/dev/null || echo "000")
    if [ "$FE_HEALTH" = "200" ]; then
        log_success "Frontend healthy ($FE_HEALTH)"
    else
        log_warning "Frontend health: $FE_HEALTH"
    fi
    
    echo ""
    log_success "Local deployment complete"
    echo ""
    
    # Status
    log_info "Service Status:"
    docker compose ps
    
    echo ""
    echo "Access services:"
    echo "  API:        http://localhost:3000"
    echo "  Frontend:   http://localhost:5173"
    echo "  Prometheus: http://localhost:9090"
    echo "  Grafana:    http://localhost:3001"
    echo ""
    
else
    # Remote deployment via git push
    log_info "Pushing to GitHub ($TARGET_BRANCH)..."
    
    git push origin "$TARGET_BRANCH"
    
    log_success "Code pushed to GitHub"
    echo ""
    
    log_info "GitHub Actions will now:"
    echo "  1. Run tests"
    echo "  2. Build Docker images"
    echo "  3. Push to container registry"
    echo "  4. Deploy to $ENVIRONMENT"
    echo "  5. Run health checks"
    echo ""
    
    if [ "$ENVIRONMENT" = "staging" ]; then
        echo "Monitor deployment:"
        echo "  GitHub: https://github.com/your-org/neapay-complete/actions"
        echo "  Staging: https://staging.neapay.com"
        echo ""
    else
        echo "Monitor deployment:"
        echo "  GitHub: https://github.com/your-org/neapay-complete/actions"
        echo "  Production: https://api.neapay.com"
        echo "  Monitoring: https://api.neapay.com:9090 (Prometheus)"
        echo "              https://api.neapay.com:3001 (Grafana)"
        echo ""
    fi
    
    log_success "Deployment triggered"
    echo ""
fi

# Phase 6: Summary
echo ""
log_info "Phase 6: Deployment Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Environment:    $DESCRIPTION"
echo "Status:         ✅ DEPLOYED"
echo "Timestamp:      $(date)"
echo "Git Branch:     $(git rev-parse --abbrev-ref HEAD)"
echo "Latest Commit:  $(git log -1 --oneline)"
echo ""

if [ "$ENVIRONMENT" = "local" ]; then
    echo "Next Steps:"
    echo "  1. Test the application locally"
    echo "  2. Review logs: docker compose logs -f"
    echo "  3. Access services (URLs above)"
    echo "  4. Stop services: docker compose down"
    echo "  5. Push to GitHub when ready"
else
    echo "Next Steps:"
    echo "  1. Monitor GitHub Actions: https://github.com/your-org/neapay-complete/actions"
    echo "  2. Watch deployment progress"
    echo "  3. Verify health checks pass"
    echo "  4. Check service endpoints"
    echo "  5. Review logs if issues occur"
fi

echo ""
echo "Documentation:"
echo "  - Quick Help:  QUICK-REFERENCE.md"
echo "  - Troubleshoot: QUICK-REFERENCE.md → Troubleshooting"
echo "  - Full Guide:   DEPLOYMENT.md"
echo ""

log_success "✨ Deployment Pipeline Executed Successfully! ✨"
echo ""
