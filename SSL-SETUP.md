# NeaPay Complete - SSL/TLS Setup

## Quick Setup (Let's Encrypt + Nginx)

### Prerequisites

```bash
# On both staging and production servers
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

### Configure Nginx Reverse Proxy

Create `/etc/nginx/sites-available/neapay`:

```nginx
# For staging
upstream api_backend {
    server 127.0.0.1:3000;
}

upstream frontend_backend {
    server 127.0.0.1:5173;
}

server {
    listen 80;
    server_name staging.neapay.com;
    
    # API
    location /api/ {
        proxy_pass http://api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
    
    # Frontend
    location / {
        proxy_pass http://frontend_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

For **production**, change:
- `server_name` to `api.neapay.com`
- `upstream` ports appropriately

### Enable Nginx

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/neapay /etc/nginx/sites-enabled/neapay

# Test configuration
sudo nginx -t

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Get SSL Certificate

```bash
# Using Let's Encrypt (staging)
sudo certbot certonly --nginx -d staging.neapay.com

# Using Let's Encrypt (production)
sudo certbot certonly --nginx -d api.neapay.com

# Or wildcard (requires DNS verification)
sudo certbot certonly --manual --preferred-challenges dns -d "*.neapay.com"
```

### Update Nginx for HTTPS

Edit `/etc/nginx/sites-available/neapay`:

```nginx
upstream api_backend {
    server 127.0.0.1:3000;
}

upstream frontend_backend {
    server 127.0.0.1:5173;
}

# HTTP redirect
server {
    listen 80;
    server_name staging.neapay.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name staging.neapay.com;
    
    ssl_certificate /etc/letsencrypt/live/staging.neapay.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/staging.neapay.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # API
    location /api/ {
        proxy_pass http://api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
    
    # Frontend
    location / {
        proxy_pass http://frontend_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # SPA support
        error_page 404 =200 /index.html;
    }
}
```

### Test and Reload

```bash
# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Verify HTTPS
curl https://staging.neapay.com
```

### Auto-Renewal

```bash
# Check renewal status
sudo certbot renew --dry-run

# Certbot automatically renews certificates
# Verify with:
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

## Update Docker Environment

Update `.env.production`:

```bash
VITE_API_URL=https://api.neapay.com
API_URL=https://api.neapay.com
```

## Update Deployment Workflow

In `.github/workflows/deploy-production.yml`, update health checks to use HTTPS:

```yaml
- name: Smoke tests
  run: |
    ssh ... << 'EOF'
    # Use HTTPS through nginx
    curl -s https://api.neapay.com/health | grep -q "ok"
    EOF
```

## Advanced: Rate Limiting

Add to Nginx config:

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=frontend_limit:10m rate=30r/s;

location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    proxy_pass http://api_backend;
    ...
}

location / {
    limit_req zone=frontend_limit burst=50 nodelay;
    proxy_pass http://frontend_backend;
    ...
}
```

## Monitoring SSL

```bash
# Check certificate expiration
sudo certbot certificates

# Watch expiration
echo "0 3 1 * * certbot renew --quiet" | sudo tee -a /etc/crontab
```

## Troubleshooting

### Certificate Not Found

```bash
# Check certificate location
sudo ls -la /etc/letsencrypt/live/

# Regenerate if needed
sudo certbot delete --cert-name staging.neapay.com
sudo certbot certonly --nginx -d staging.neapay.com
```

### Mixed Content Warning

Ensure `.env` uses HTTPS URLs:
```bash
VITE_API_URL=https://api.neapay.com  # Not http://
```

### Nginx Not Starting

```bash
# Check logs
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```
