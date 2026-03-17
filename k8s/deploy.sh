#!/usr/bin/env bash
# Kubernetes deployment script for NeaPay Complete

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

NAMESPACE=${1:-neapay}
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "NeaPay Complete - Kubernetes Deployment"
log_info "Namespace: $NAMESPACE"
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl."
    exit 1
fi

log_info "Current Kubernetes context: $(kubectl config current-context)"
echo ""

# Deploy namespace and config
log_info "Creating namespace and configuration..."
kubectl apply -f "$K8S_DIR/neapay-namespace.yaml"
log_success "Namespace configured"

# Update secrets (must be done manually)
log_warning "⚠️  UPDATE SECRETS BEFORE DEPLOYING:"
log_warning "   kubectl edit secret neapay-secrets -n $NAMESPACE"
echo ""

# Deploy API
log_info "Deploying API..."
kubectl apply -f "$K8S_DIR/neapay-api-deployment.yaml"
log_success "API deployed"

# Deploy Frontend
log_info "Deploying Frontend..."
kubectl apply -f "$K8S_DIR/neapay-frontend-deployment.yaml"
log_success "Frontend deployed"

# Wait for rollout
log_info "Waiting for deployments to be ready..."
kubectl rollout status deployment/neapay-api -n "$NAMESPACE" --timeout=5m
kubectl rollout status deployment/neapay-frontend -n "$NAMESPACE" --timeout=5m
log_success "Deployments ready"

# Show status
echo ""
log_info "Deployment Status:"
kubectl get pods -n "$NAMESPACE" -o wide
echo ""
kubectl get svc -n "$NAMESPACE"
echo ""

log_success "Kubernetes deployment complete"
log_info "Access frontend: kubectl port-forward -n $NAMESPACE svc/neapay-frontend 8080:80"
log_info "Access API: kubectl port-forward -n $NAMESPACE svc/neapay-api 3000:80"
