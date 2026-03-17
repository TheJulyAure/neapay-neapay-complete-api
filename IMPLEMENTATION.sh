#!/usr/bin/env bash
# IMPLEMENTATION GUIDE - Execute these commands in order

set -euo pipefail

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                   NeaPay Complete Deployment Pipeline                      ║
║                        Implementation Execution Guide                       ║
╚════════════════════════════════════════════════════════════════════════════╝

This guide walks through the complete deployment setup step by step.
Time estimate: 2-3 hours

PREREQUISITES:
- GitHub repository access (admin)
- 2 Linux servers (Ubuntu/Debian 20.04+)
- SSH keys setup
- gh (GitHub CLI) installed locally
- Docker knowledge (basic)

EOF

echo "Press Enter to start..."
read

# ============================================================================
# SECTION 1: LOCAL SETUP
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║ SECTION 1: LOCAL SETUP ON YOUR MACHINE                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Step 1.1: Verify GitHub CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI installed: $(gh --version)"
else
    echo "❌ GitHub CLI not found"
    echo "Install from: https://cli.github.com"
    exit 1
fi
echo ""

echo "📋 Step 1.2: Generate SSH Keys"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Generate SSH keys? (yes/no) [yes]: " gen_ssh
gen_ssh=${gen_ssh:-yes}

if [ "$gen_ssh" = "yes" ]; then
    echo ""
    echo "Generating staging key..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_neapay_staging -C "neapay-staging-deploy" -N ""
    
    echo "Generating production key..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_neapay_prod -C "neapay-prod-deploy" -N ""
    
    echo ""
    echo "✅ Keys generated:"
    ls -lh ~/.ssh/id_neapay_*
fi
echo ""

echo "📋 Step 1.3: Setup GitHub Secrets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Opening GitHub secrets setup wizard..."
echo ""
read -p "Continue? (yes/no) [yes]: " setup_secrets
setup_secrets=${setup_secrets:-yes}

if [ "$setup_secrets" = "yes" ] && [ -f "github-setup.sh" ]; then
    chmod +x github-setup.sh
    ./github-setup.sh
fi
echo ""

# ============================================================================
# SECTION 2: STAGING SERVER SETUP
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║ SECTION 2: STAGING SERVER SETUP                                           ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Step 2.1: Prepare Staging Server Credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Staging server IP/hostname: " staging_host
read -p "Staging server SSH user (usually 'root'): " staging_user

echo ""
echo "Testing SSH connection..."
if ssh -o ConnectTimeout=5 "$staging_user@$staging_host" "echo ✅ Connection OK" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ Cannot connect to staging server"
    echo "Check: IP, user, and firewall rules"
    exit 1
fi
echo ""

echo "📋 Step 2.2: Run Server Setup on Staging"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Run staging setup? (yes/no) [yes]: " setup_staging
setup_staging=${setup_staging:-yes}

if [ "$setup_staging" = "yes" ]; then
    echo ""
    echo "Copying setup script..."
    scp setup-server.sh "$staging_user@$staging_host":/tmp/
    
    echo "Running setup (this takes 5-10 minutes)..."
    ssh "$staging_user@$staging_host" "sudo bash /tmp/setup-server.sh staging"
    
    echo ""
    echo "✅ Staging server setup complete"
fi
echo ""

echo "📋 Step 2.3: Configure SSH Key for Deploy User"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Add SSH public key to staging? (yes/no) [yes]: " add_key_staging
add_key_staging=${add_key_staging:-yes}

if [ "$add_key_staging" = "yes" ]; then
    cat ~/.ssh/id_neapay_staging.pub | ssh "$staging_user@$staging_host" \
        "sudo -u deploy sh -c 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
    
    echo "Testing SSH as deploy user..."
    if ssh -i ~/.ssh/id_neapay_staging deploy@"$staging_host" "echo ✅ Deploy user OK" 2>/dev/null; then
        echo "✅ Deploy user SSH access configured"
    fi
fi
echo ""

echo "📋 Step 2.4: Create Environment File"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Configure .env.staging? (yes/no) [yes]: " config_env_staging
config_env_staging=${config_env_staging:-yes}

if [ "$config_env_staging" = "yes" ]; then
    echo ""
    echo "You'll need to edit the environment file on the staging server:"
    echo "  ssh -i ~/.ssh/id_neapay_staging deploy@$staging_host"
    echo "  nano /opt/neapay-complete/.env.staging"
    echo ""
    echo "Update these values:"
    echo "  - DATABASE_URL (PostgreSQL connection)"
    echo "  - POSTGRES_PASSWORD"
    echo "  - REDIS_URL"
    echo "  - REDIS_PASSWORD"
    echo "  - API_KEY"
    echo "  - SECRET_KEY"
    echo ""
    read -p "Press Enter when done..."
fi
echo ""

# ============================================================================
# SECTION 3: PRODUCTION SERVER SETUP
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║ SECTION 3: PRODUCTION SERVER SETUP                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "⚠️  WARNING: This section configures your PRODUCTION environment"
echo "    Proceed with caution and double-check all information"
echo ""
read -p "Continue to production setup? (yes/no) [no]: " continue_prod
continue_prod=${continue_prod:-no}

if [ "$continue_prod" != "yes" ]; then
    echo "Production setup skipped"
else
    echo "📋 Step 3.1: Prepare Production Server Credentials"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Production server IP/hostname: " prod_host
    read -p "Production server SSH user (usually 'root'): " prod_user
    
    echo ""
    echo "Testing SSH connection..."
    if ssh -o ConnectTimeout=5 "$prod_user@$prod_host" "echo ✅ Connection OK" 2>/dev/null; then
        echo "✅ SSH connection successful"
    else
        echo "❌ Cannot connect to production server"
        exit 1
    fi
    echo ""
    
    echo "📋 Step 3.2: Run Server Setup on Production"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Copying setup script..."
    scp setup-server.sh "$prod_user@$prod_host":/tmp/
    
    echo "Running setup (this takes 5-10 minutes)..."
    ssh "$prod_user@$prod_host" "sudo bash /tmp/setup-server.sh production"
    
    echo ""
    echo "✅ Production server setup complete"
    echo ""
    
    echo "📋 Step 3.3: Configure SSH Key for Deploy User"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat ~/.ssh/id_neapay_prod.pub | ssh "$prod_user@$prod_host" \
        "sudo -u deploy sh -c 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
    
    echo "Testing SSH as deploy user..."
    if ssh -i ~/.ssh/id_neapay_prod deploy@"$prod_host" "echo ✅ Deploy user OK" 2>/dev/null; then
        echo "✅ Deploy user SSH access configured"
    fi
    echo ""
fi

# ============================================================================
# SECTION 4: VERIFICATION
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║ SECTION 4: VERIFICATION                                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Checking all prerequisites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

checks_passed=0
checks_total=0

# Check SSH keys
checks_total=$((checks_total+1))
if [ -f ~/.ssh/id_neapay_staging ] && [ -f ~/.ssh/id_neapay_prod ]; then
    echo "✅ SSH keys generated"
    checks_passed=$((checks_passed+1))
else
    echo "❌ SSH keys missing"
fi

# Check GitHub CLI
checks_total=$((checks_total+1))
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI installed"
    checks_passed=$((checks_passed+1))
else
    echo "❌ GitHub CLI missing"
fi

# Check staging connection
if [ -n "${staging_host:-}" ]; then
    checks_total=$((checks_total+1))
    if ssh -i ~/.ssh/id_neapay_staging deploy@"$staging_host" "docker --version" &>/dev/null; then
        echo "✅ Staging server ready (Docker installed)"
        checks_passed=$((checks_passed+1))
    else
        echo "❌ Staging server not ready"
    fi
fi

echo ""
echo "Setup Status: $checks_passed/$checks_total checks passed"
echo ""

# ============================================================================
# SECTION 5: NEXT STEPS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║ NEXT STEPS                                                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "1️⃣  Complete Configuration"
echo "    ├─ Edit .env files on servers with actual values"
echo "    ├─ Set up SSL/TLS (SSL-SETUP.md)"
echo "    └─ Configure backups (BACKUP-STRATEGY.md)"
echo ""
echo "2️⃣  Test Pipeline"
echo "    ├─ Push to develop: git push origin develop"
echo "    ├─ Monitor at: GitHub → Actions"
echo "    └─ Verify staging deployment"
echo ""
echo "3️⃣  Deploy to Production"
echo "    ├─ Test thoroughly on staging"
echo "    ├─ Push to main: git push origin main"
echo "    └─ Monitor deployment"
echo ""
echo "4️⃣  Post-Deployment"
echo "    ├─ Verify services running"
echo "    ├─ Check monitoring/logging"
echo "    ├─ Test backups"
echo "    └─ Document setup"
echo ""
echo "📚 Documentation:"
echo "    - DEPLOYMENT.md (full guide)"
echo "    - DEPLOYMENT-CHECKLIST.md (verification)"
echo "    - SSL-SETUP.md (HTTPS configuration)"
echo "    - BACKUP-STRATEGY.md (data protection)"
echo ""
echo "🚀 Quick Commands:"
echo "    bash quickstart.sh          (interactive menu)"
echo "    ./deploy-cli.sh help        (all deployment commands)"
echo ""
echo "✅ Implementation guide complete!"
echo ""
