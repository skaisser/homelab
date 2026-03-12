# ☁️ Cloud Storage Integration #backup #cloud #rclone #b2 #s3

Integrate cloud storage into your homelab backup strategy for offsite redundancy. This guide covers affordable cloud options and automated sync workflows.

## Table of Contents

1. [Cloud Backup Options](#cloud-backup-options)
2. [Installing rclone](#installing-rclone)
3. [Backblaze B2 Setup](#backblaze-b2-setup)
4. [AWS S3 Configuration](#aws-s3-configuration)
5. [Encryption with rclone crypt](#encryption-with-rclone-crypt)
6. [Automated Sync Scripts](#automated-sync-scripts)
7. [Bandwidth Management](#bandwidth-management)
8. [Cost Estimation](#cost-estimation)
9. [Monitoring Backups](#monitoring-backups)
10. [Troubleshooting](#troubleshooting)

## Cloud Backup Options

### Backblaze B2
- **Cost:** $0.006/GB/month + $0.01/GB egress
- **Best for:** Low-cost offsite backups
- **Pros:** Cheapest, simple API, good for cold storage
- **Cons:** Slow restore, egress charges

### Wasabi
- **Cost:** $0.0049/GB/month, no egress fee
- **Best for:** Balanced price and performance
- **Pros:** No egress charges, S3-compatible, good speed
- **Cons:** Slightly higher storage cost

### AWS S3
- **Cost:** $0.023/GB/month + egress
- **Best for:** Integration with AWS ecosystem
- **Pros:** Reliable, many features, integration options
- **Cons:** Expensive, complex pricing

### Google Drive
- **Cost:** $1.99-9.99/month for 100GB-2TB
- **Best for:** Small backups, integration with Google services
- **Pros:** Familiar interface, integration with Google apps
- **Cons:** Limited API, slow syncs, terms of service concerns

## Installing rclone

### Download and Install

```bash
# Download rclone (check for latest version)
curl https://rclone.org/install.sh | sudo bash

# Verify installation
rclone version

# List installed remotes
rclone listremotes
```

### Basic Configuration

```bash
# Interactive configuration
rclone config

# Non-interactive config addition
rclone config create mycloud s3 provider AWS access_key_id YOUR_KEY secret_access_key YOUR_SECRET
```

## Backblaze B2 Setup

### Create B2 Account and Application Key

1. Sign up at https://www.backblaze.com/b2/cloud-storage.html
2. Create B2 bucket
3. Create Application Key with access to specific bucket

### Configure rclone for B2

```bash
# Interactive setup
rclone config

# When prompted:
# name: b2
# type: b2
# account_id: [your app key ID]
# application_key: [your app key]

# Or directly:
rclone config create b2 b2 account_id YOUR_APP_ID application_key YOUR_APP_KEY

# Test connection
rclone lsd b2:
```

### Sync to B2

```bash
# One-way sync (push to cloud)
rclone sync /mnt/backup/local b2:your-bucket-name/homelab --progress

# With deletion (removes files from cloud not in local)
rclone sync /mnt/backup/local b2:your-bucket-name/homelab --delete-extraneous --progress

# Dry-run to preview changes
rclone sync /mnt/backup/local b2:your-bucket-name/homelab --dry-run
```

## AWS S3 Configuration

### Create S3 Bucket

```bash
# Using AWS CLI
aws s3 mb s3://your-homelab-backups --region us-east-1

# Set lifecycle policy for cost savings
aws s3api put-bucket-lifecycle-configuration \
  --bucket your-homelab-backups \
  --lifecycle-configuration '{"Rules":[{"Id":"Archive","Status":"Enabled","Transitions":[{"Days":30,"StorageClass":"GLACIER"}]}]}'
```

### Configure rclone for S3

```bash
# Create S3 remote
rclone config create s3 s3 \
  provider AWS \
  access_key_id YOUR_ACCESS_KEY \
  secret_access_key YOUR_SECRET_KEY \
  region us-east-1

# Verify
rclone lsd s3:
```

### Sync to S3

```bash
# Basic sync
rclone sync /mnt/backup/local s3:your-homelab-backups --progress

# With metadata
rclone sync /mnt/backup/local s3:your-homelab-backups --progress --metadata
```

## Encryption with rclone crypt

### Create Encrypted Remote

```bash
# First, configure your cloud provider (b2, s3, etc.)
rclone config create b2 b2 ...

# Create encrypted wrapper
rclone config create encrypted crypt remote b2:your-bucket base64 true

# When prompted:
# password: [choose strong password]
# password2: [confirm password]
```

### Use Encrypted Remote

```bash
# All operations through 'encrypted:' automatically encrypt
rclone sync /mnt/backup/local encrypted:homelab-backup --progress

# List encrypted backups
rclone lsd encrypted:homelab-backup

# Restore (automatically decrypts)
rclone copy encrypted:homelab-backup/important /restore/path
```

### Encryption Benefits

- Server cannot read your data
- Protects against provider snooping
- Meets compliance requirements
- Small performance overhead

## Automated Sync Scripts

### Basic Sync Script

```bash
#!/bin/bash
# File: /usr/local/bin/cloud-backup-sync.sh

RCLONE_CONFIG="/home/user/.config/rclone/rclone.conf"
BACKUP_SOURCE="/mnt/backup/local"
CLOUD_DEST="b2:your-bucket-name/homelab"
LOG_FILE="/var/log/cloud-backup-sync.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting cloud backup sync..."

# Check if backup directory exists
if [ ! -d "$BACKUP_SOURCE" ]; then
    log "ERROR: Backup source not found: $BACKUP_SOURCE"
    exit 1
fi

# Perform sync
rclone sync "$BACKUP_SOURCE" "$CLOUD_DEST" \
    --config "$RCLONE_CONFIG" \
    --progress \
    --log-level INFO \
    --log-file "$LOG_FILE" \
    --delete-extraneous \
    --no-traverse

if [ $? -eq 0 ]; then
    log "Cloud backup sync completed successfully"
    SIZE=$(rclone size "$CLOUD_DEST" --json | jq -r '.bytes')
    log "Cloud backup size: $((SIZE / 1024 / 1024 / 1024)) GB"
else
    log "ERROR: Cloud backup sync failed"
    exit 1
fi
```

### Systemd Timer for Automated Sync

```bash
# Create service: /etc/systemd/system/cloud-backup-sync.service
[Unit]
Description=Cloud Backup Sync Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=user
ExecStart=/usr/local/bin/cloud-backup-sync.sh
StandardOutput=journal
StandardError=journal

# Create timer: /etc/systemd/system/cloud-backup-sync.timer
[Unit]
Description=Cloud Backup Sync Timer
Requires=cloud-backup-sync.service

[Timer]
OnBootSec=30min
OnUnitActiveSec=6h
Persistent=true
AccuracySec=5min

[Install]
WantedBy=timers.target

# Enable
sudo systemctl daemon-reload
sudo systemctl enable --now cloud-backup-sync.timer
```

## Bandwidth Management

### Limit Upload Speed

```bash
# Limit to 1 Mbps (125 KB/s)
rclone sync /mnt/backup/local b2:bucket --bwlimit 125k --progress

# Different limits for upload/download
rclone sync /mnt/backup/local b2:bucket --bwlimit 125k,512k --progress
```

### Scheduled Uploads (Off-peak)

```bash
# Sync only between 1-6 AM (off-peak hours)
rclone sync /mnt/backup/local b2:bucket \
    --bwlimit off,256k \
    --cutoff-mode soft
```

## Cost Estimation

### Monthly Cost Calculator

```bash
#!/bin/bash
# Estimate cloud backup costs

BACKUP_SIZE_GB=500  # Your backup size
MONTHLY_GROWTH_GB=50  # Monthly new data

# Backblaze B2
B2_STORAGE=$((BACKUP_SIZE_GB * 6)) # $0.006 per GB
B2_EGRESS=$((BACKUP_SIZE_GB * 10)) # Estimate 10 retrieves per month * 1 GB each = 0.01
TOTAL_B2=$(echo "scale=2; ($B2_STORAGE + $B2_EGRESS) / 1000" | bc)

echo "Backblaze B2: \$$TOTAL_B2/month"

# Wasabi
WASABI_STORAGE=$((BACKUP_SIZE_GB * 5)) # $0.0049 per GB
echo "Wasabi: \$$(echo "scale=2; $WASABI_STORAGE / 1000" | bc)/month"

# AWS S3
S3_STORAGE=$((BACKUP_SIZE_GB * 23)) # $0.023 per GB
echo "AWS S3: \$$(echo "scale=2; $S3_STORAGE / 1000" | bc)/month"
```

## Monitoring Backups

### Check Cloud Backup Size

```bash
# Backblaze B2
rclone size b2:your-bucket-name/homelab

# AWS S3
aws s3 ls s3://your-homelab-backups --recursive --summarize

# Human-readable format
rclone size b2:your-bucket-name/homelab --json | \
    jq -r '.bytes / 1024 / 1024 / 1024 | round | "\(.)GB"'
```

### Create Monitoring Script

```bash
#!/bin/bash
# Monitor cloud backup health

BACKUP_SIZE=$(rclone size b2:bucket --json | jq -r '.bytes / 1024 / 1024 / 1024')
LAST_SYNC=$(stat -c %y /mnt/backup/local | awk '{print $1}')

echo "Cloud Backup Status:"
echo "  Size: ${BACKUP_SIZE}GB"
echo "  Last sync: $LAST_SYNC"
echo "  Remote files: $(rclone size b2:bucket --json | jq -r '.count')"
```

### Set Up Alerts

```bash
# Check if sync is outdated (more than 24 hours old)
if [ $(( $(date +%s) - $(stat -c %Y /mnt/backup/local) )) -gt 86400 ]; then
    echo "WARNING: Backup not synced in 24 hours" | mail -s "Backup Alert" admin@example.com
fi
```

## Troubleshooting

### Issue: Slow upload speed
```bash
# Check network connectivity
speedtest-cli

# Increase parallel uploads
rclone sync /source cloud:dest --transfers 8 --checkers 16

# Use checksum mode for faster syncs
rclone sync /source cloud:dest --fast-list
```

### Issue: Sync keeps failing
```bash
# Check rclone logs
tail -f /var/log/cloud-backup-sync.log

# Verify cloud credentials
rclone lsd b2: --dump auth

# Test remote access
rclone ls b2:your-bucket-name --max-items 5
```

### Issue: High egress costs
```bash
# Avoid unnecessary downloads
rclone sync cloud:dest /local --dry-run  # Preview first

# Use cheaper archive storage (AWS Glacier)
rclone copyto b2:bucket aws-glacier:bucket --storage-class GLACIER

# Limit retrieve operations
```

---

✅ Set up automated cloud backups with encryption for offsite redundancy
