# 🧹 System Cleanup and Maintenance #maintenance #cleanup #disk-space #docker

Regular cleanup prevents disk space issues, improves system performance, and reduces attack surface. Implement automated cleanup procedures.

## Table of Contents

1. [Why Cleanup Matters](#why-cleanup-matters)
2. [apt Package Cleanup](#apt-package-cleanup)
3. [Docker System Cleanup](#docker-system-cleanup)
4. [Log Rotation](#log-rotation)
5. [Journal Size Limits](#journal-size-limits)
6. [Kernel Cleanup](#kernel-cleanup)
7. [Temporary File Cleanup](#temporary-file-cleanup)
8. [Application Cache Cleanup](#application-cache-cleanup)
9. [Automated Cleanup Scripts](#automated-cleanup-scripts)
10. [Safe Cleanup Practices](#safe-cleanup-practices)

## Why Cleanup Matters

### Impact of Neglecting Cleanup

```bash
# Without cleanup over 2 years:
# - Old packages: 5-10GB
# - Docker artifacts: 20-50GB
# - Logs: 10-20GB
# - Journal: 5-10GB
# Total: 40-90GB wasted

# Benefits of regular cleanup:
# 1. Free disk space
# 2. Faster system performance
# 3. Reduced security exposure
# 4. Lower backup costs
# 5. Fewer disk I/O issues
```

## apt Package Cleanup

### Remove Unused Packages

```bash
# List unused packages (automatically installed dependencies)
sudo apt autoremove --dry-run

# Remove unused packages
sudo apt autoremove -y

# Alternative: remove with purge (removes configuration too)
sudo apt autoremove --purge -y
```

### Clean Package Cache

```bash
# Remove cached .deb files for uninstalled packages
sudo apt autoclean

# Remove all cached .deb files
sudo apt clean

# Check cache size before
du -sh /var/cache/apt/

# After cleanup
du -sh /var/cache/apt/
```

### Complete apt Cleanup Workflow

```bash
#!/bin/bash
# File: /usr/local/bin/cleanup-packages.sh

echo "Package Cleanup Report"
echo "====================="

# Step 1: Update package info
sudo apt-get update

# Step 2: Show orphaned packages
echo "Unused packages to remove:"
sudo apt autoremove --dry-run | grep -E "^Remov|^Purg" | head -20

# Step 3: Remove unused packages
echo "Removing unused packages..."
sudo apt autoremove -y

# Step 4: Clean cache
echo "Cleaning package cache..."
BEFORE=$(du -s /var/cache/apt/ | awk '{print $1}')
sudo apt autoclean
AFTER=$(du -s /var/cache/apt/ | awk '{print $1}')
FREED=$((BEFORE - AFTER))

echo "Cache cleaned: freed ${FREED}KB"

# Step 5: Remove unnecessary files
echo "Removing old kernels..."
sudo apt-get install -y --purge $(dpkg --get-selections | grep linux-image | grep deinstall | cut -f1)
```

## Docker System Cleanup

### Remove Unused Images

```bash
# List unused images
docker images --filter "dangling=true"

# Remove dangling images
docker image prune -f

# Remove all unused images (not just dangling)
docker image prune -a -f

# Remove images older than 24 hours
docker image prune -a --filter "until=24h"
```

### Remove Unused Containers

```bash
# List stopped containers
docker ps -a --filter "status=exited"

# Remove stopped containers
docker container prune -f

# Remove containers exited more than 24 hours ago
docker container prune -f --filter "until=24h"
```

### Remove Unused Volumes

```bash
# List unused volumes
docker volume ls --filter "dangling=true"

# Remove unused volumes
docker volume prune -f

# Remove all unused volumes
docker volume prune -f --all

# WARNING: Check before removing
# docker volume inspect [volume_id]
```

### Remove Build Cache

```bash
# Show build cache size
docker system df

# Remove build cache
docker builder prune -f

# Remove all build cache and dependencies
docker builder prune -af
```

### Complete Docker Cleanup Script

```bash
#!/bin/bash
# File: /usr/local/bin/cleanup-docker.sh

echo "Docker System Cleanup"
echo "===================="

# Show initial disk usage
echo "Before cleanup:"
docker system df

# Remove stopped containers
echo "Removing stopped containers..."
docker container prune -f

# Remove dangling images
echo "Removing dangling images..."
docker image prune -f

# Remove unused volumes
echo "Removing unused volumes..."
docker volume prune -f

# Remove build cache
echo "Removing build cache..."
docker builder prune -f

# Remove networks
echo "Removing unused networks..."
docker network prune -f

# Show final disk usage
echo "After cleanup:"
docker system df

# Calculate freed space
TOTAL=$(docker system df --format "{{.Size}}")
echo "Estimated space: $TOTAL"
```

### Automated Docker Cleanup Container

```bash
# Run docker-gc container for automated cleanup
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /etc:/etc:ro \
    spotify/docker-gc
```

## Log Rotation

### Configure logrotate

```bash
# View existing logrotate configurations
ls -la /etc/logrotate.d/

# Check logrotate status
sudo logrotate -f /etc/logrotate.conf

# View log rotation schedule
cat /etc/logrotate.conf

# Manually rotate specific log
sudo logrotate -f /etc/logrotate.d/syslog
```

### Create Custom Log Rotation

```bash
# Create rotation config for custom application
sudo tee /etc/logrotate.d/myapp > /dev/null << 'EOF'
/var/log/myapp/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 myapp myapp
    sharedscripts
    postrotate
        /usr/lib/myapp/logrotate-post.sh
    endscript
}
EOF

# Test configuration
sudo logrotate -d /etc/logrotate.d/myapp
```

### Common Rotation Parameters

```bash
# /etc/logrotate.d/example
/var/log/app/*.log {
    daily           # Rotate daily (weekly, monthly, yearly)
    rotate 7        # Keep 7 rotated logs
    compress        # gzip rotated logs
    delaycompress   # Compress previous rotation, not current
    notifempty      # Don't rotate empty files
    missingok       # Don't error if file missing
    create 0644 user group  # Create new log file with permissions
    maxage 30       # Delete logs older than 30 days
    maxsize 100M    # Rotate if file exceeds 100MB
    postrotate
        # Run command after rotation
        systemctl reload myapp
    endscript
}
```

## Journal Size Limits

### Check Journal Size

```bash
# Current journal size
journalctl --disk-usage

# Show oldest and newest log entry
journalctl -n 1 --quiet
journalctl -r -n 1 --quiet
```

### Limit Journal Size

```bash
# Edit: /etc/systemd/journald.conf
sudo nano /etc/systemd/journald.conf

# Add or modify:
# SystemMaxUse=2G          # Total journal size limit
# RuntimeMaxUse=500M       # Limit for /run
# MaxFileSec=1month        # Keep journals for max 1 month

# Or set directly
sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=2G/' /etc/systemd/journald.conf
sudo sed -i 's/#MaxFileSec=/MaxFileSec=1month/' /etc/systemd/journald.conf

# Restart journald
sudo systemctl restart systemd-journald
```

### Cleanup Old Journal Entries

```bash
# Remove journal entries older than 30 days
sudo journalctl --vacuum-time=30d

# Remove journal files until journal uses less than 500MB
sudo journalctl --vacuum-size=500M

# Keep only newest 100 journal files
sudo journalctl --vacuum-files=100
```

## Kernel Cleanup

### Remove Old Kernels

```bash
# List installed kernels
dpkg -l | grep linux-image

# Show current running kernel
uname -r

# List kernels to remove (keep current + 2-3 recent)
dpkg --get-selections | grep linux-image | grep -v "$(uname -r | sed 's/-generic.*//')"

# Safe removal (keep current kernel)
sudo apt-get remove --purge $(dpkg --get-selections | grep linux-image | grep deinstall | cut -f1)

# Or manually
sudo apt-get remove --purge linux-image-5.4.0-42-generic
```

### Automatic Kernel Cleanup

```bash
#!/bin/bash
# File: /usr/local/bin/cleanup-kernels.sh

# Get current kernel version
CURRENT=$(uname -r)
KEEP_COUNT=3  # Keep 3 most recent kernels

# Get list of installed kernels
KERNELS=$(dpkg --get-selections | grep linux-image | grep install | cut -f1 | sort -V)

# Count kernels
COUNT=$(echo "$KERNELS" | wc -l)

if [ "$COUNT" -le "$KEEP_COUNT" ]; then
    echo "Only $COUNT kernels installed, keeping all"
    exit 0
fi

# Remove old kernels
echo "$KERNELS" | head -n $((COUNT - KEEP_COUNT)) | while read kernel; do
    if [[ "$kernel" != *"$CURRENT"* ]]; then
        echo "Removing $kernel..."
        sudo apt-get remove --purge -y "$kernel"
    fi
done

# Cleanup headers
sudo apt-get remove --purge -y $(dpkg --get-selections | grep linux-headers | grep deinstall | cut -f1)
```

## Temporary File Cleanup

### Clean /tmp and /var/tmp

```bash
# Remove files older than 10 days from /tmp
sudo find /tmp -type f -atime +10 -delete

# Remove files older than 30 days from /var/tmp
sudo find /var/tmp -type f -atime +30 -delete

# Clean /tmp on boot
# Edit: /etc/systemd/system/tmp.mount
# Add: Options=mode=1777,strictatime,nodev,nosuid,noexec,size=4G

# Remove temporary files
sudo systemctl reload-or-restart systemd-tmpfiles-setup.service
```

### Browser Cache Cleanup (Desktop)

```bash
# Chrome/Chromium
rm -rf ~/.cache/google-chrome/
rm -rf ~/.cache/chromium/

# Firefox
rm -rf ~/.cache/mozilla/
rm -rf ~/.mozilla/firefox/*.default-release/cache2/

# General cache
rm -rf ~/.cache/*
```

## Application Cache Cleanup

### Database Cache

```bash
# PostgreSQL
psql -U postgres -d template1 -c "VACUUM ANALYZE;"

# MySQL
mysql -u root -p -e "OPTIMIZE TABLE \`database\`.*;"

# Redis
redis-cli FLUSHALL
```

### Package Manager Cache

```bash
# npm cache
npm cache clean --force

# pip cache
pip cache purge

# Ruby gem cache
gem cleanup
```

## Automated Cleanup Scripts

### Comprehensive Cleanup Script

```bash
#!/bin/bash
# File: /usr/local/bin/full-system-cleanup.sh

set -e

LOG_FILE="/var/log/system-cleanup-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Starting full system cleanup..."

    # Get initial disk space
    BEFORE=$(df / | tail -1 | awk '{print $3}')

    log "1/6: Cleaning apt cache..."
    sudo apt-get clean
    sudo apt-get autoclean

    log "2/6: Removing unused packages..."
    sudo apt-get autoremove -y

    log "3/6: Vacuuming journal..."
    sudo journalctl --vacuum-time=30d

    log "4/6: Cleaning Docker..."
    docker container prune -f || true
    docker image prune -f || true
    docker volume prune -f || true

    log "5/6: Removing temporary files..."
    sudo find /tmp -type f -atime +7 -delete
    sudo find /var/tmp -type f -atime +14 -delete

    log "6/6: Removing old log files..."
    sudo find /var/log -type f -name "*.log.*" -delete

    # Calculate freed space
    AFTER=$(df / | tail -1 | awk '{print $3}')
    FREED=$((BEFORE - AFTER))

    log "Cleanup complete! Freed: ${FREED}KB"
    log "Current usage: $(df -h / | tail -1 | awk '{print $5}')"
}

cleanup
chmod 600 "$LOG_FILE"
```

### Schedule Automated Cleanup

```bash
# /etc/systemd/system/system-cleanup.timer
[Unit]
Description=System Cleanup Timer
Requires=system-cleanup.service

[Timer]
OnBootSec=1h
OnUnitActiveSec=1w
OnCalendar=*-*-01 03:00:00

[Install]
WantedBy=timers.target

# /etc/systemd/system/system-cleanup.service
[Unit]
Description=System Cleanup Service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/full-system-cleanup.sh
StandardOutput=journal
StandardError=journal

# Enable
sudo systemctl daemon-reload
sudo systemctl enable --now system-cleanup.timer
```

## Safe Cleanup Practices

### Pre-Cleanup Checklist

```bash
# 1. Verify backups exist
ls -la /mnt/backup/
rclone size b2:bucket

# 2. Check disk space first
df -h

# 3. Never delete current kernel
uname -r

# 4. Don't clean if system is running low on space
AVAIL=$(df / | tail -1 | awk '{print $4}')
if [ "$AVAIL" -lt 1000000 ]; then
    echo "Less than 1GB available, cleanup risky"
fi
```

### Dry-Run Before Cleanup

```bash
# Test cleanup without making changes
docker container prune --dry-run
docker image prune --dry-run
sudo apt autoremove --dry-run

# Review what will be removed
apt autoremove --dry-run | grep "^Purg\|^Remov"
```

---

✅ Implement regular cleanup schedule to reclaim disk space, maintain performance, and reduce security exposure
