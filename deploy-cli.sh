#!/usr/bin/env bash
# Makefile-style deployment targets for NeaPay Complete

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

COMMAND=${1:-help}

case $COMMAND in
  build)
    echo "Building Docker images..."
    docker compose build
    log_success "Build complete"
    ;;
  
  test)
    echo "Running tests..."
    docker compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit
    docker compose -f docker-compose.yml -f docker-compose.test.yml down
    log_success "Tests complete"
    ;;
  
  staging-up)
    echo "Starting staging environment..."
    docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
    sleep 5
    docker compose ps
    ;;
  
  staging-down)
    echo "Stopping staging environment..."
    docker compose -f docker-compose.yml -f docker-compose.staging.yml down
    ;;
  
  staging-logs)
    docker compose -f docker-compose.yml -f docker-compose.staging.yml logs -f
    ;;
  
  prod-up)
    echo "Starting production environment..."
    docker compose -f docker-compose.yml -f docker-compose.production.yml up -d
    sleep 10
    docker compose ps
    ;;
  
  prod-down)
    echo "Stopping production environment..."
    docker compose -f docker-compose.yml -f docker-compose.production.yml down
    ;;
  
  prod-logs)
    docker compose -f docker-compose.yml -f docker-compose.production.yml logs -f
    ;;
  
  deploy-staging)
    echo "Deploying to staging..."
    chmod +x deploy.sh
    ./deploy.sh staging
    ;;
  
  deploy-prod)
    echo "Deploying to production..."
    chmod +x deploy.sh
    ./deploy.sh production
    ;;
  
  k8s-deploy)
    echo "Deploying to Kubernetes..."
    chmod +x k8s/deploy.sh
    k8s/deploy.sh "${2:-neapay}"
    ;;
  
  k8s-status)
    NAMESPACE="${2:-neapay}"
    kubectl get deployments,pods,svc -n "$NAMESPACE"
    ;;
  
  clean)
    echo "Cleaning up..."
    docker compose down -v
    docker system prune -f
    log_success "Cleanup complete"
    ;;
  
  help|*)
    cat << 'EOF'
NeaPay Complete Deployment Commands

Docker Compose:
  make build              - Build Docker images
  make test               - Run test suite
  
Staging (Docker Compose):
  make staging-up         - Start staging environment
  make staging-down       - Stop staging environment
  make staging-logs       - View staging logs
  
Production (Docker Compose):
  make prod-up            - Start production environment
  make prod-down          - Stop production environment
  make prod-logs          - View production logs
  
Deployment:
  make deploy-staging     - Deploy to staging server
  make deploy-prod        - Deploy to production server
  
Kubernetes:
  make k8s-deploy         - Deploy to Kubernetes cluster
  make k8s-status         - View Kubernetes status
  
Maintenance:
  make clean              - Clean up all containers and volumes

Example:
  ./deploy-cli.sh build
  ./deploy-cli.sh staging-up
  ./deploy-cli.sh deploy-staging
EOF
    ;;
esac
