# Database Backup Strategy

## Automated PostgreSQL Backups

### Setup Backup Script

Create `/opt/neapay-backups/backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/opt/neapay-backups"
DB_USER="neapay"
DB_NAME="neapay"
CONTAINER_NAME="neapay-postgres"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/postgres-backup-$DATE.sql.gz"
RETENTION_DAYS=30

# Create backup
docker compose exec -T postgres pg_dump -U $DB_USER $DB_NAME | gzip > "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# List current backups
echo ""
echo "Backups:"
ls -lh "$BACKUP_DIR"/postgres-backup-*.sql.gz | tail -10

# Cleanup old backups
find "$BACKUP_DIR" -name "postgres-backup-*.sql.gz" -mtime +$RETENTION_DAYS -delete
echo "Deleted backups older than $RETENTION_DAYS days"
```

### Setup Cron Job

```bash
# On both staging and production servers
sudo crontab -e

# Add these lines:

# Daily backup at 2 AM
0 2 * * * /opt/neapay-backups/backup.sh >> /var/log/neapay-backup.log 2>&1

# Weekly backup to S3 (see below)
0 3 * * 0 /opt/neapay-backups/backup-to-s3.sh >> /var/log/neapay-backup-s3.log 2>&1
```

## Cloud Backup to S3

### Install AWS CLI

```bash
sudo apt-get install -y awscli
```

### Configure AWS Credentials

```bash
aws configure
# Enter:
# AWS Access Key ID: your-key
# AWS Secret Access Key: your-secret
# Default region: us-east-1
# Default output format: json
```

### Create S3 Backup Script

Create `/opt/neapay-backups/backup-to-s3.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/opt/neapay-backups"
S3_BUCKET="neapay-backups"
S3_PREFIX="$(date +%Y/%m)"
ENVIRONMENT=${ENVIRONMENT:-staging}
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/postgres-backup-*.sql.gz | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backup found"
    exit 1
fi

# Upload to S3
FILENAME=$(basename "$LATEST_BACKUP")
aws s3 cp "$LATEST_BACKUP" "s3://$S3_BUCKET/$ENVIRONMENT/$S3_PREFIX/$FILENAME"

echo "✅ Backup uploaded to S3: s3://$S3_BUCKET/$ENVIRONMENT/$S3_PREFIX/$FILENAME"

# Keep only 1 month of S3 backups
aws s3 ls "s3://$S3_BUCKET/$ENVIRONMENT/" --recursive \
    | grep "postgres-backup" \
    | while read -r line; do
        createDate=$(echo $line | awk {'print $1" "$2'})
        createDate=$(date -d "$createDate" +%s)
        olderThan=$(date --date "60 days ago" +%s)
        if [[ $createDate -lt $olderThan ]]; then
            fileName=$(echo $line | awk {'print $4'})
            echo "Deleting s3://$S3_BUCKET/$fileName"
            aws s3 rm "s3://$S3_BUCKET/$fileName"
        fi
    done
```

### Create S3 Bucket

```bash
# Only needed once
aws s3 mb s3://neapay-backups --region us-east-1

# Set bucket versioning
aws s3api put-bucket-versioning \
    --bucket neapay-backups \
    --versioning-configuration Status=Enabled

# Set lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
    --bucket neapay-backups \
    --lifecycle-configuration '{
  "Rules": [
    {
      "Id": "DeleteOldVersions",
      "Status": "Enabled",
      "NoncurrentVersionExpirationInDays": 90
    }
  ]
}'
```

## Restore from Backup

### From Local Backup

```bash
# List available backups
ls -lh /opt/neapay-backups/postgres-backup-*.sql.gz

# Restore specific backup
BACKUP_FILE="/opt/neapay-backups/postgres-backup-20240115_020000.sql.gz"

# Stop services
docker compose down

# Start only database
docker compose up -d postgres

# Wait for database to be ready
sleep 5

# Restore
gunzip < "$BACKUP_FILE" | docker compose exec -T postgres psql -U neapay

# Verify
docker compose exec postgres psql -U neapay -c "SELECT COUNT(*) FROM pg_catalog.pg_tables;"

# Start all services
docker compose up -d
```

### From S3 Backup

```bash
# Download from S3
BACKUP_DATE="20240115"
aws s3 cp "s3://neapay-backups/production/2024/01/postgres-backup-${BACKUP_DATE}_020000.sql.gz" ./

# Restore
gunzip < "postgres-backup-${BACKUP_DATE}_020000.sql.gz" | docker compose exec -T postgres psql -U neapay
```

## Redis Backup

### Manual Backup

```bash
# Create RDB backup
docker compose exec -T redis redis-cli BGSAVE

# Copy from container
docker compose cp redis:/data/dump.rdb /opt/neapay-backups/redis-backup-$(date +%Y%m%d_%H%M%S).rdb
```

### Restore Redis

```bash
# Stop services
docker compose down

# Copy backup to container volume
docker run --rm -v neapay-redis:/data -v /opt/neapay-backups:/backups \
    alpine cp /backups/redis-backup-20240115_020000.rdb /data/dump.rdb

# Start services
docker compose up -d
```

## Backup Verification

### Automated Verification

Add to backup script:

```bash
# Verify backup integrity
gunzip -t "$BACKUP_FILE" || {
    echo "❌ Backup is corrupted"
    exit 1
}

# Test restore to temp database
docker compose exec -T postgres createdb -U neapay test_restore || true
gunzip < "$BACKUP_FILE" | docker compose exec -T postgres psql -U neapay -d test_restore

# Drop test database
docker compose exec -T postgres dropdb -U neapay test_restore

echo "✅ Backup verified successfully"
```

### Manual Verification

```bash
# List backup contents without extracting
gunzip -c backup.sql.gz | head -50

# Check for key tables
gunzip -c backup.sql.gz | grep "CREATE TABLE" | wc -l
```

## Monitoring Backups

### Check Backup Status

```bash
# SSH to server
ssh deploy@production.neapay.com

# List recent backups
ls -lhS /opt/neapay-backups/postgres-backup-*.sql.gz | head -5

# Check disk space
du -sh /opt/neapay-backups/

# Check last backup time
stat -c %y /opt/neapay-backups/postgres-backup-*.sql.gz | tail -1

# Check cron logs
sudo grep "backup" /var/log/syslog | tail -20
```

### Alert on Failed Backups

Add to crontab:

```bash
# Email if backup fails
0 2 * * * /opt/neapay-backups/backup.sh || \
    echo "Backup failed on $(hostname)" | mail -s "Backup Alert" ops@neapay.com
```

## Point-in-Time Recovery (PITR)

### Enable WAL Archiving

Add to docker-compose.production.yml:

```yaml
postgres:
  environment:
    POSTGRES_INITDB_ARGS: "-c wal_level=replica -c max_wal_senders=3"
  volumes:
    - postgres-wal:/var/lib/postgresql/pg_wal
```

### Archive WAL Files to S3

```bash
#!/usr/bin/env bash
# wal-archive.sh
WAL_FILE=$1
aws s3 cp - "s3://neapay-backups/wal/$WAL_FILE" < "$WAL_FILE" || exit 1
```

Configure PostgreSQL:

```yaml
postgres:
  environment:
    POSTGRES_INITDB_ARGS: "-c wal_level=replica -c archive_mode=on -c archive_command='/wal-archive.sh %p'"
```

## Testing Disaster Recovery

### Schedule Monthly Test

```bash
# 1st Sunday of month at 4 AM
0 4 * * 0 [ $(date +\%d) -le 07 ] && /opt/neapay-backups/test-restore.sh
```

Create `test-restore.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Testing disaster recovery..."

# Get latest backup
BACKUP=$(ls -t /opt/neapay-backups/postgres-backup-*.sql.gz | head -1)

# Create test database
docker compose exec -T postgres createdb -U neapay test_dr || true

# Restore to test database
gunzip < "$BACKUP" | docker compose exec -T postgres psql -U neapay -d test_dr 2>&1

# Run tests
TABLES=$(docker compose exec -T postgres psql -U neapay -d test_dr -t -c \
    "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE schemaname='public';")

if [ "$TABLES" -gt 0 ]; then
    echo "✅ Disaster recovery test passed ($TABLES tables restored)"
    # Email success
    echo "DR Test Success: $TABLES tables restored" | mail -s "DR Test" ops@neapay.com
else
    echo "❌ Disaster recovery test failed"
    # Email failure
    echo "DR Test Failed: No tables restored" | mail -s "DR Test Alert" ops@neapay.com
    exit 1
fi

# Cleanup
docker compose exec -T postgres dropdb -U neapay test_dr
```

## Backup Checklist

- [ ] Daily backups automated via cron
- [ ] Backups encrypted in transit (S3 HTTPS)
- [ ] Backups encrypted at rest (S3 KMS)
- [ ] Retention policy set (30 days local, 60 days S3)
- [ ] Backups tested monthly
- [ ] Restore procedure documented
- [ ] PITR configured (optional but recommended)
- [ ] Team trained on restore process
- [ ] Monitoring alerts configured
- [ ] Compliance requirements verified
