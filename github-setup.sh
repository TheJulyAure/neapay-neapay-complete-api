#!/usr/bin/env bash
# GitHub Secrets Setup Script
# Automates adding secrets to GitHub repository

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

# Check gh CLI
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed"
    echo "Install from: https://cli.github.com"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    log_error "Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

log_info "GitHub Secrets Setup"
echo ""

# Get repository
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
log_info "Repository: $REPO"
echo ""

# Function to prompt for secret
prompt_secret() {
    local name=$1
    local description=$2
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Secret: $name"
    echo "Description: $description"
    echo ""
    read -p "Enter value (or 'skip' to skip): " value
    
    if [ "$value" != "skip" ] && [ -n "$value" ]; then
        gh secret set "$name" --body "$value"
        log_success "Secret $name added"
    else
        log_warning "Skipped $name"
    fi
}

# Staging Secrets
echo ""
echo "═══════════════════════════════════════════════════════"
echo "STAGING CONFIGURATION"
echo "═══════════════════════════════════════════════════════"

prompt_secret "STAGING_HOST" "Staging server hostname/IP (e.g., staging.neapay.com)"
prompt_secret "STAGING_USER" "Staging server SSH user (usually 'deploy')"
prompt_secret "STAGING_SSH_KEY" "Staging server SSH private key (full PEM format)"

# Production Secrets
echo ""
echo "═══════════════════════════════════════════════════════"
echo "PRODUCTION CONFIGURATION"
echo "═══════════════════════════════════════════════════════"

prompt_secret "PROD_HOST" "Production server hostname/IP (e.g., api.neapay.com)"
prompt_secret "PROD_USER" "Production server SSH user (usually 'deploy')"
prompt_secret "PROD_SSH_KEY" "Production server SSH private key (full PEM format)"

# Registry Secrets
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CONTAINER REGISTRY CONFIGURATION"
echo "═══════════════════════════════════════════════════════"

prompt_secret "REGISTRY_USERNAME" "GitHub username (for GHCR)"
prompt_secret "REGISTRY_PASSWORD" "GitHub Personal Access Token (read:packages scope)"

# Optional: Slack
echo ""
echo "═══════════════════════════════════════════════════════"
echo "NOTIFICATIONS (OPTIONAL)"
echo "═══════════════════════════════════════════════════════"

prompt_secret "SLACK_WEBHOOK" "Slack Incoming Webhook URL (https://hooks.slack.com/...)"

# List all secrets
echo ""
echo "═══════════════════════════════════════════════════════"
log_info "Added Secrets Summary"
echo "═══════════════════════════════════════════════════════"

gh secret list

echo ""
log_success "GitHub secrets setup complete!"
echo ""
log_info "Next Steps:"
echo "  1. Verify all secrets are set: gh secret list"
echo "  2. Push code to trigger workflows: git push"
echo "  3. Monitor: GitHub → Actions"
