# 💾 Local Backup Solutions #backup #rsync #restic #borgbackup #local

Implement efficient local backup solutions for your homelab. Choose based on your needs: rsync for simplicity, restic for deduplication and encryption, or BorgBackup for efficiency.

## Table of Contents

1. [Tool Comparison](#tool-comparison)
2. [rsync Backups](#rsync-backups)
3. [restic Repository Setup](#restic-repository-setup)
4. [BorgBackup Basics](#borgbackup-basics)
5. [ZFS Snapshots](#zfs-snapshots)
6. [USB Drive Rotation](#usb-drive-rotation)
7. [NAS as Backup Target](#nas-as-backup-target)
8. [Scheduling with Cron](#scheduling-with-cron)
9. [Backup Verification](#backup-verification)
10. [Troubleshooting](#troubleshooting)

## Tool Comparison

| Feature | rsync | restic | BorgBackup |
|---------|-------|--------|-----------|
| Deduplication | No | Yes | Yes |
| Encryption | No | Yes | Yes |
| Incremental | Yes | Yes | Yes |
| Ease of use | Simple | Moderate | Moderate |
| Storage efficiency | 60-70% | 40-50% | 30-40% |
| Restore speed | Fast | Moderate | Moderate |
| Best for | File sync | Secure backups | Space savings |

## rsync Backups

### Basic rsync Setup

```bash
# Install rsync
sudo apt-get update && sudo apt-get install rsync

# Simple backup
rsync -av /home/user/documents /mnt/backup/

# Backup with deletion (mirror)
rsync -av --delete /home/user/documents /mnt/backup/documents

# Archive mode (preserves permissions, timestamps)
rsync -av --archive /home/user/documents /mnt/backup/
```

### Advanced rsync Options

```bash
# Comprehensive backup with common options
rsync -av \
    --archive \
    --verbose \
    --progress \
    --delete \
    --exclude='*.iso' \
    --exclude='.cache' \
    --exclude='Downloads' \
    --compress \
    --hard-links \
    /home/user/ \
    /mnt/backup/home-backup/

# Incremental backups (based on mtime)
rsync -av --delete --backup --backup-dir=/mnt/backup/incremental-$(date +%Y%m%d) /home/user/ /mnt/backup/latest/
```

### Remote rsync Backups

```bash
# Backup to remote server over SSH
rsync -av -e "ssh -i ~/.ssh/backup_key" /home/user/ backupuser@remote.example.com:/backups/homelab/

# Backup from remote server
rsync -av -e "ssh" backupuser@remote.example.com:/data/ /mnt/local-backup/

# Restrict rsync over SSH
# Add to remote ~/.ssh/authorized_keys:
# command="rsync --server --daemon --config=/etc/rsyncd.conf .",no-port-forwarding,no-X11-forwarding ssh-rsa AAAA...
```

### rsync Backup Script

```bash
#!/bin/bash
# File: /usr/local/bin/backup-with-rsync.sh

BACKUP_DEST="/mnt/backup"
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
LOG_FILE="/var/log/rsync-backup-$BACKUP_DATE.log"

# Array of source directories
SOURCES=(
    "/home"
    "/etc"
    "/opt"
)

echo "Starting rsync backup at $(date)" > "$LOG_FILE"

for source in "${SOURCES[@]}"; do
    echo "Backing up $source..." >> "$LOG_FILE"
    rsync -av \
        --delete \
        --exclude='*.tmp' \
        --exclude='.cache' \
        --compress \
        "$source/" \
        "$BACKUP_DEST/$(basename $source)/" \
        >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "✓ $source backed up" >> "$LOG_FILE"
    else
        echo "✗ Failed to backup $source" >> "$LOG_FILE"
    fi
done

echo "Backup completed" >> "$LOG_FILE"
chmod 600 "$LOG_FILE"
```

## restic Repository Setup

### Initialize restic Repository

```bash
# Install restic
wget https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_linux_amd64.bz2
bunzip2 restic_0.16.0_linux_amd64.bz2
sudo mv restic_0.16.0_linux_amd64 /usr/local/bin/restic
sudo chmod +x /usr/local/bin/restic

# Create backup directory
mkdir -p /mnt/backup/restic-repo

# Initialize repository (will prompt for password)
restic -r /mnt/backup/restic-repo init

# Store password for automated backups
echo "your-secure-password" > ~/.restic-password
chmod 600 ~/.restic-password
```

### Create restic Backups

```bash
# Set password environment variable
export RESTIC_PASSWORD="your-secure-password"

# Create backup
restic -r /mnt/backup/restic-repo backup /home/user/important --verbose

# Backup multiple paths
restic -r /mnt/backup/restic-repo backup /home /etc /opt

# Exclude patterns
restic -r /mnt/backup/restic-repo backup /home \
    --exclude='*.iso' \
    --exclude='.cache' \
    --exclude='node_modules'
```

### Manage restic Snapshots

```bash
# List all backups
restic -r /mnt/backup/restic-repo snapshots

# List specific backup contents
restic -r /mnt/backup/restic-repo ls latest

# Find a specific file
restic -r /mnt/backup/restic-repo find backup.sql

# Show backup statistics
restic -r /mnt/backup/restic-repo stats
```

### Restore from restic

```bash
# Restore latest backup
restic -r /mnt/backup/restic-repo restore latest --target /restore/location

# Restore specific snapshot
restic -r /mnt/backup/restic-repo restore abc123de --target /restore/location

# Restore single file
restic -r /mnt/backup/restic-repo restore latest --target / --include 'home/user/important.txt'
```

### restic Backup Script

```bash
#!/bin/bash
# File: /usr/local/bin/backup-with-restic.sh

export RESTIC_PASSWORD=$(cat ~/.restic-password)
BACKUP_REPO="/mnt/backup/restic-repo"
LOG_FILE="/var/log/restic-backup.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "Starting restic backup..."

# Create backup
restic -r "$BACKUP_REPO" backup /home /etc /opt \
    --exclude='*.cache' \
    --verbose \
    >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log_msg "Backup completed successfully"
    restic -r "$BACKUP_REPO" snapshots >> "$LOG_FILE"
else
    log_msg "Backup failed"
    exit 1
fi

# Cleanup old snapshots (keep last 7 days)
log_msg "Running prune..."
restic -r "$BACKUP_REPO" forget --keep-daily 7 --prune >> "$LOG_FILE" 2>&1

# Verify
log_msg "Running verification..."
restic -r "$BACKUP_REPO" check >> "$LOG_FILE" 2>&1
```

## BorgBackup Basics

### Initialize BorgBackup

```bash
# Install BorgBackup
sudo apt-get install borgbackup

# Create repository
mkdir -p /mnt/backup/borg-repo
borg init -e repokey /mnt/backup/borg-repo

# Set password environment variable
export BORG_PASSPHRASE="your-secure-password"
```

### Create BorgBackup Archives

```bash
# Export password (for automated backups)
export BORG_PASSPHRASE=$(cat ~/.borg-password)

# Create archive
borg create /mnt/backup/borg-repo::{hostname}-{now} /home /etc

# Create archive with compression
borg create -C lz4 /mnt/backup/borg-repo::{hostname}-{now:%Y-%m-%d} /home

# Exclude patterns
borg create \
    --exclude '*.iso' \
    --exclude '.cache' \
    --exclude 'Downloads' \
    /mnt/backup/borg-repo::{hostname}-{now} \
    /home
```

### Manage BorgBackup Archives

```bash
# List repositories
borg list /mnt/backup/borg-repo

# List contents of archive
borg list /mnt/backup/borg-repo::hostname-2026-03-12T10:00:00

# Show archive statistics
borg info /mnt/backup/borg-repo::hostname-2026-03-12T10:00:00

# Repository statistics
borg info /mnt/backup/borg-repo
```

### Restore from BorgBackup

```bash
# Extract entire archive
cd /tmp/restore
borg extract /mnt/backup/borg-repo::hostname-2026-03-12T10:00:00

# Extract single file/directory
borg extract /mnt/backup/borg-repo::hostname-2026-03-12T10:00:00 home/user/important.txt

# Mount archive (read-only)
mkdir /mnt/borg-mount
borg mount /mnt/backup/borg-repo::hostname-2026-03-12T10:00:00 /mnt/borg-mount
ls /mnt/borg-mount/home
umount /mnt/borg-mount
```

## ZFS Snapshots

### Create ZFS Snapshots

```bash
# Create snapshot
sudo zfs snapshot tank/data@backup-$(date +%Y%m%d-%H%M%S)

# List snapshots
sudo zfs list -t snapshot

# Show snapshot size
sudo zfs list -t snapshot -o name,used,referenced
```

### Send Snapshots to Backup

```bash
# Incremental snapshot send
sudo zfs send tank/data@snap-old tank/data@snap-new | ssh backup-server "zfs receive backup/data-inc"

# Send to file
sudo zfs send tank/data@backup-today > /mnt/backup/tank-data-backup.zfs

# Restore from snapshot file
sudo zfs receive tank/restored < /mnt/backup/tank-data-backup.zfs
```

## USB Drive Rotation

### Setup Rotating USB Backups

```bash
#!/bin/bash
# File: /usr/local/bin/backup-usb-rotate.sh

# Format USB drive
# sudo mkfs.ext4 /dev/sdX1

MOUNT_POINT="/mnt/backup-usb"
SOURCE="/home /etc"

# Find next USB drive
USB_DEVICE=$(lsblk -d -o NAME -n | grep -E '^sd' | head -1)

if [ -z "$USB_DEVICE" ]; then
    echo "No USB device found"
    exit 1
fi

echo "Using device: /dev/$USB_DEVICE"
sudo mount /dev/${USB_DEVICE}1 "$MOUNT_POINT" 2>/dev/null || {
    echo "Mounting /dev/${USB_DEVICE}1..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount /dev/${USB_DEVICE}1 "$MOUNT_POINT"
}

# Backup
rsync -av --delete $SOURCE "$MOUNT_POINT/homelab-backup/"

# Safely eject
sudo umount "$MOUNT_POINT"
echo "USB backup complete, safe to remove"
```

## NAS as Backup Target

### Mount NAS Share

```bash
# Create mount point
sudo mkdir -p /mnt/nas-backup

# Mount SMB share
sudo mount -t cifs \
    //nas-ip-address/share \
    /mnt/nas-backup \
    -o username=backupuser,password=password,uid=$USER,gid=$USER

# Add to /etc/fstab for persistent mounting
echo "//nas-ip-address/share /mnt/nas-backup cifs username=backupuser,password=password,uid=$USER,gid=$USER 0 0" | sudo tee -a /etc/fstab
```

### NFS Mount (preferred for Linux)

```bash
# Mount NFS share
sudo mkdir -p /mnt/nas-backup
sudo mount -t nfs -o soft,timeo=10,retrans=3 nas-ip:/export/backups /mnt/nas-backup

# Persistent mount
echo "nas-ip:/export/backups /mnt/nas-backup nfs soft,timeo=10,retrans=3 0 0" | sudo tee -a /etc/fstab
```

## Scheduling with Cron

### Basic Cron Schedule

```bash
# Edit crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-local.sh

# Twice daily
0 2 * * * /usr/local/bin/backup-local.sh
0 14 * * * /usr/local/bin/backup-local.sh

# Weekly full backup Sunday 3 AM
0 3 * * 0 /usr/local/bin/backup-full.sh

# Monthly 1st day of month
0 4 1 * * /usr/local/bin/backup-monthly.sh
```

### Systemd Timer Schedule

```bash
# /etc/systemd/system/local-backup.timer
[Unit]
Description=Local Backup Timer
Requires=local-backup.service

[Timer]
OnBootSec=10min
OnUnitActiveSec=1d
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target

# Enable
sudo systemctl daemon-reload
sudo systemctl enable --now local-backup.timer
```

## Backup Verification

### Verify Backup Integrity

```bash
# Test rsync without making changes
rsync -av --dry-run /source/ /destination/

# Check restic backup
restic -r /mnt/backup/restic-repo check

# Verify BorgBackup
borg verify /mnt/backup/borg-repo

# Test restore
mkdir -p /tmp/test-restore
restic -r /mnt/backup/restic-repo restore latest --target /tmp/test-restore
diff -r /home/user/important /tmp/test-restore/home/user/important
rm -rf /tmp/test-restore
```

## Troubleshooting

### Issue: "Permission denied" errors
```bash
# Run backup as root
sudo /usr/local/bin/backup-local.sh

# Or fix file ownership
sudo chown -R $USER:$USER /mnt/backup
```

### Issue: Backup takes too long
```bash
# Check disk speed
dd if=/dev/zero of=/mnt/test bs=1M count=1024 && rm /mnt/test

# Monitor I/O
iostat -x 1 10

# Use compression for network backups only
```

### Issue: Backup repository corrupted
```bash
# BorgBackup recovery
borg check --repair /mnt/backup/borg-repo

# restic recovery
restic -r /mnt/backup/restic-repo repair index
```

---

✅ Choose local backup tool (rsync/restic/BorgBackup) and set up automated local backups
