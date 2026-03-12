# 🛡️ Backup Strategy: The 3-2-1 Framework #backup #strategy #3-2-1 #disaster-recovery

A robust backup strategy is the foundation of homelab reliability. This guide implements the industry-standard 3-2-1 backup rule with practical examples for your homelab environment.

## Table of Contents

1. [Understanding the 3-2-1 Rule](#understanding-the-3-2-1-rule)
2. [Assessing What to Back Up](#assessing-what-to-back-up)
3. [Backup Types Explained](#backup-types-explained)
4. [Choosing Backup Tools](#choosing-backup-tools)
5. [Implementing Local Backups](#implementing-local-backups)
6. [Offsite and Cloud Backups](#offsite-and-cloud-backups)
7. [Scheduling and Automation](#scheduling-and-automation)
8. [Testing and Verification](#testing-and-verification)
9. [Backup Retention Policies](#backup-retention-policies)
10. [Encryption Best Practices](#encryption-best-practices)
11. [Troubleshooting](#troubleshooting)
12. [Implementation Plan](#implementation-plan)

## Understanding the 3-2-1 Rule

The 3-2-1 backup rule states:
- **3 copies** of your data (original + 2 backups)
- **2 different storage media** (e.g., internal HDD + external SSD)
- **1 offsite copy** (cloud or physical location away from home)

This approach protects against hardware failure, data corruption, and location-based disasters.

### Example Architecture

```
Production Data
    ↓
├── Local Backup 1 (NAS via rsync)
├── Local Backup 2 (USB external drive)
└── Offsite Backup (Cloud: B2/S3)
```

## Assessing What to Back Up

Start by inventorying your critical data:

```bash
# List your important directories
find /home -maxdepth 2 -type d -size +100M | head -20

# Calculate total data size
du -sh /home/user/documents
du -sh /var/lib/docker
du -sh /etc
```

**Critical homelab data to back up:**
- `/home` - User documents, configurations, settings
- `/etc` - System configurations
- `/var/lib/docker` - Container volumes and data
- `/opt` - Custom applications
- Database directories (`/var/lib/mysql`, `/var/lib/postgresql`)
- VM images and Proxmox configurations

## Backup Types Explained

### Full Backup
Complete copy of all selected data. Largest size, longest duration, easiest restore.

```bash
# Full backup example with rsync
rsync -av --delete /home/user/important /mnt/backup/full-backup-$(date +%Y%m%d)/
```

### Incremental Backup
Only backs up data changed since the last backup. Smallest size, needs all previous backups for restore.

```bash
# Incremental backup with tar
tar -cf /mnt/backup/backup-$(date +%Y%m%d).tar.gz --listed-incremental=/mnt/backup/backup.snar /home/user/important
```

### Differential Backup
Only backs up data changed since the last full backup. Balance between full and incremental.

```bash
# Differential backup example
find /home/user/important -newer /tmp/last-full-backup -type f -exec cp {} /mnt/backup/diff-backup/ \;
```

### Snapshot-Based
Point-in-time copies using filesystem capabilities (ZFS, LVM, Btrfs).

```bash
# ZFS snapshot
zfs snapshot tank/data@backup-$(date +%Y%m%d-%H%M%S)

# List snapshots
zfs list -t snapshot
```

## Choosing Backup Tools

### rsync
**Best for:** Simple file synchronization, local backups, bandwidth-efficient transfers

```bash
# Install rsync
sudo apt-get install rsync

# Basic backup command
rsync -av --delete /source/ /destination/

# With compression and progress
rsync -avz --progress --delete /source/ /destination/

# Exclude patterns
rsync -av --delete --exclude='*.log' --exclude='.cache' /home/user/ /mnt/backup/
```

### restic
**Best for:** Encrypted, deduplicated backups with versioning

```bash
# Install restic
wget https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_linux_amd64.bz2
bunzip2 restic_0.16.0_linux_amd64.bz2
sudo mv restic_0.16.0_linux_amd64 /usr/local/bin/restic
sudo chmod +x /usr/local/bin/restic

# Initialize a repository
restic init -r /mnt/backup/restic-repo
export RESTIC_PASSWORD="your-secure-password"

# Create backup
restic -r /mnt/backup/restic-repo backup /home/user/important

# List backups
restic -r /mnt/backup/restic-repo snapshots

# Restore
restic -r /mnt/backup/restic-repo restore latest --target /restore/path
```

### BorgBackup
**Best for:** Efficient, deduplicated backups with compression

```bash
# Install BorgBackup
sudo apt-get install borgbackup

# Initialize repository
borg init -e repokey /mnt/backup/borg-repo

# Create backup
borg create /mnt/backup/borg-repo::{hostname}-{now} /home/user/important

# List archives
borg list /mnt/backup/borg-repo

# Extract backup
borg extract /mnt/backup/borg-repo::hostname-2026-03-12T10:00:00
```

### Proxmox Backup Server
**Best for:** VM and container backups, enterprise-grade deduplication

```bash
# Configure PBS as backup target in Proxmox WebUI
# Administration → Backup → Edit

# Command-line backup (on PBS)
sudo proxmox-backup-client backup pbs:local /mnt/data

# List backup jobs
proxmox-backup-client list
```

## Implementing Local Backups

### Setup: NAS as Backup Target

```bash
# Create network share mount point
sudo mkdir -p /mnt/nas-backup
sudo chown $USER:$USER /mnt/nas-backup

# Mount SMB share
sudo mount -t cifs //nas-ip/backup /mnt/nas-backup -o username=user,password=pass,uid=$USER,gid=$USER
```

### Automated Backup Script

```bash
#!/bin/bash
# File: /usr/local/bin/backup-homelab.sh

BACKUP_TARGET="/mnt/nas-backup/homelab"
SOURCE_DIRS="/home /etc /opt"
LOG_FILE="/var/log/homelab-backup.log"
RETENTION_DAYS=30

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting homelab backup..."

# Create dated backup directory
BACKUP_DIR="$BACKUP_TARGET/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup each source
for source in $SOURCE_DIRS; do
    log_message "Backing up $source..."
    rsync -av --delete "$source/" "$BACKUP_DIR/$(basename $source)/" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log_message "✓ Successfully backed up $source"
    else
        log_message "✗ Error backing up $source"
    fi
done

# Remove old backups
log_message "Removing backups older than $RETENTION_DAYS days..."
find "$BACKUP_TARGET" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

log_message "Backup completed successfully"
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/backup-homelab.sh
```

## Offsite and Cloud Backups

### Backblaze B2 Integration

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure B2
rclone config create b2 b2 account_id YOUR_APP_KEY_ID application_key YOUR_APP_KEY

# Upload backup to B2
rclone sync /mnt/backup/local b2:your-bucket-name/homelab-backup

# Encrypted upload
rclone sync /mnt/backup/local :crypt: b2:your-bucket-name/homelab-backup
```

### AWS S3 Backup

```bash
# Configure S3
rclone config create s3 s3 provider AWS access_key_id YOUR_ACCESS_KEY secret_access_key YOUR_SECRET_KEY region us-east-1

# Upload to S3
rclone sync /mnt/backup/local s3:your-bucket-name/homelab-backup --progress
```

## Scheduling and Automation

### Cron-Based Scheduling

```bash
# Edit crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-homelab.sh

# Weekly full backup every Sunday at 3 AM
0 3 * * 0 /usr/local/bin/backup-full.sh

# Monthly backup first day of month
0 4 1 * * /usr/local/bin/backup-monthly.sh
```

### Systemd Timer-Based Scheduling

```bash
# Create service file: /etc/systemd/system/homelab-backup.service
[Unit]
Description=Homelab Backup Service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-homelab.sh
StandardOutput=journal
StandardError=journal

# Create timer file: /etc/systemd/system/homelab-backup.timer
[Unit]
Description=Homelab Backup Timer
Requires=homelab-backup.service

[Timer]
OnBootSec=10min
OnUnitActiveSec=1d
OnCalendar=*-*-* 02:00:00
AccuracySec=5min

[Install]
WantedBy=timers.target

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now homelab-backup.timer
sudo systemctl status homelab-backup.timer
```

## Testing and Verification

### Backup Integrity Check

```bash
# Verify rsync backup
rsync -av --dry-run /source/ /destination/

# Check restic backup integrity
restic -r /mnt/backup/restic-repo check

# Verify BorgBackup
borg verify /mnt/backup/borg-repo

# Calculate checksum
find /mnt/backup -type f -exec sha256sum {} \; > /tmp/backup.sha256
sha256sum -c /tmp/backup.sha256
```

### Test Restore Process

```bash
# Create test directory
mkdir -p /tmp/restore-test

# Test restore from restic
restic -r /mnt/backup/restic-repo restore latest --target /tmp/restore-test

# Verify restored data
diff -r /home/user/important /tmp/restore-test/home/user/important

# Cleanup
rm -rf /tmp/restore-test
```

## Backup Retention Policies

Define how long to keep backups:

```bash
#!/bin/bash
# Retention policy script

# Keep daily backups for 7 days
find /mnt/backup/daily -mtime +7 -delete

# Keep weekly backups for 4 weeks
find /mnt/backup/weekly -mtime +28 -delete

# Keep monthly backups for 1 year
find /mnt/backup/monthly -mtime +365 -delete

# Keep yearly backups indefinitely
# (no deletion rule)
```

## Encryption Best Practices

### Encrypting Backups with GPG

```bash
# Create GPG key
gpg --full-generate-key

# Encrypt backup tarball
tar -czf backup.tar.gz /home/user/important
gpg --output backup.tar.gz.gpg --encrypt --recipient your-email@example.com backup.tar.gz

# Decrypt backup
gpg --output backup.tar.gz --decrypt backup.tar.gz.gpg
tar -xzf backup.tar.gz
```

### Encrypting with rclone

```bash
# Create encrypted remote
rclone config create crypt crypt remote b2:your-bucket base64 true

# All operations through 'crypt:' automatically encrypt
rclone sync /mnt/backup crypt:encrypted-backup
```

### LUKS Encrypted External Drive

```bash
# Create LUKS volume
sudo cryptsetup luksFormat /dev/sdb1
sudo cryptsetup luksOpen /dev/sdb1 backup-drive
sudo mkfs.ext4 /dev/mapper/backup-drive

# Mount
sudo mkdir -p /mnt/backup-external
sudo mount /dev/mapper/backup-drive /mnt/backup-external

# Backup to encrypted drive
rsync -av /home/user/important /mnt/backup-external/
```

## Troubleshooting

### Issue: Backup taking too long
```bash
# Check disk I/O
iostat -x 1 5

# Monitor rsync progress
rsync -avz --progress --stats /source/ /destination/

# Increase bandwidth/CPU allocation
```

### Issue: Not enough storage
```bash
# Find largest directories
du -sh /* | sort -hr | head -10

# Check backup deduplication ratio
borg info /mnt/backup/borg-repo
restic -r /mnt/backup/restic-repo stats
```

### Issue: Permission errors
```bash
# Run backup as root if needed
sudo /usr/local/bin/backup-homelab.sh

# Fix permissions on backup location
sudo chown -R $USER:$USER /mnt/backup
```

## Implementation Plan

**Week 1:**
- Inventory critical data
- Choose backup tool (recommend: restic for encryption + simplicity)
- Set up local backup location (NAS or external drive)

**Week 2:**
- Configure chosen backup tool
- Create backup script
- Test backup and restore process

**Week 3:**
- Set up cloud backup (B2 recommended: cheapest)
- Configure automated scheduling
- Document retention policy

**Week 4:**
- Monitor first weekly backups
- Test restore from multiple backup points
- Document recovery procedures

---

✅ Implement the 3-2-1 rule: 3 copies, 2 storage types, 1 offsite backup
