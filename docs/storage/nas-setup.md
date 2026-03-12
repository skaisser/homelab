# 💾 Network Attached Storage Basics #storage #nas #smb #nfs #networking

Network Attached Storage (NAS) centralizes storage for your homelab, providing reliable, accessible data sharing across all devices. Whether you build a dedicated NAS from spare hardware, repurpose an old computer, or use a commercial appliance, proper configuration ensures security, performance, and reliability. This guide covers NAS concepts, setup options, share configuration, and optimization for homelab environments.

## Table of Contents

- [NAS Concepts and Planning](#nas-concepts-and-planning)
- [Hardware Considerations](#hardware-considerations)
- [Choosing a NAS OS](#choosing-a-nas-os)
- [Setting Up SMB/CIFS Shares](#setting-up-smbcifs-shares)
- [Setting Up NFS Shares](#setting-up-nfs-shares)
- [User Permissions and Access Control](#user-permissions-and-access-control)
- [RAID and ZFS Pool Planning](#raid-and-zfs-pool-planning)
- [Performance Optimization](#performance-optimization)
- [Network Configuration for NAS](#network-configuration-for-nas)
- [Monitoring Storage Health](#monitoring-storage-health)
- [Backup Integration](#backup-integration)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## NAS Concepts and Planning

### Why You Need a NAS

A NAS provides:
- **Centralized Storage** - Single source of truth for files
- **Network Access** - Accessible from all devices
- **Redundancy** - Protect against disk failures
- **Backup Target** - Store backups of VMs, containers
- **Media Serving** - Stream media to multiple devices
- **Collaboration** - Shared folders for family/team files

### NAS vs External Drives

| Feature | NAS | External Drive |
|---------|-----|-----------------|
| **Access** | Network from anywhere | Single device |
| **Redundancy** | RAID available | Single disk |
| **Performance** | 1Gbps+, Gigabit Ethernet | USB 3.0 speeds |
| **Cost** | Higher initial | Lower |
| **Scalability** | Add drives | Limited |
| **Always-on** | Designed for it | Not ideal |

## Hardware Considerations

### Dedicated NAS Hardware

```bash
#!/bin/bash
set -euo pipefail

# Recommended spec for homelab NAS:
# - CPU: Quad-core (Intel Celeron N5105 or AMD equivalent)
# - RAM: 8GB minimum (16GB for ZFS)
# - Drives: 2-4 3.5" SATA drives (8TB+)
# - Network: Gigabit Ethernet (or multi-gig if available)
# - Power: Redundant PSU (optional)
# - Cooling: Adequate for 24/7 operation

# Example hardware list:
cat <<'EOF'
NAS Build Example:
- Case: Qnap TS-253E (or similar DIY case with 4-6 bays)
- CPU: Intel N5095 (low power, 10W TDP)
- RAM: 16GB DDR4
- Drives: 2x 8TB WD Red (or equivalent NAS drives)
- Network: 1x Gigabit Ethernet + 1x optional 2.5Gbps

Cost estimate: $400-600 (Qnap), $200-300 (DIY with used parts)
EOF
```

### Repurposing Old Hardware

```bash
#!/bin/bash
set -euo pipefault

# Old laptop/desktop works if:
# - Supports multiple SATA drives
# - Has Gigabit Ethernet
# - Can run 24/7 (decent PSU needed)
# - At least 4GB RAM

# Limitations:
# - May have only 2-4 drive bays
# - Power consumption higher than modern NAS
# - Noise from cooling fans
# - Limited processor for transcoding

# Suitable uses:
# - Personal file backup
# - Media library (if not transcoding)
# - Docker/container storage
# - Development/test storage
```

## Choosing a NAS OS

### TrueNAS (Recommended for ZFS)

```bash
#!/bin/bash
set -euo pipefault

# TrueNAS Core (free, BSD-based, excellent for homelabs)
# Download: https://www.truenas.com/download-truenas-core/

# Installation overview:
# 1. Download ISO
# 2. Create bootable USB
# 3. Boot from USB
# 4. Follow installer
# 5. Configure via web UI at http://<ip>:80

# Post-install setup (via web UI):
# - Create storage pool (RAID configuration)
# - Create datasets (shares)
# - Configure SMB/NFS services
# - Set up users and permissions
# - Enable monitoring/alerts
```

### OpenMediaVault (Linux-based Alternative)

```bash
#!/bin/bash
set -euo pipefault

# OpenMediaVault (free, Debian-based, lightweight)
# Good for: Lower-spec hardware, familiar Linux users

# Install on existing Debian/Ubuntu system
wget -O - https://github.com/openmediavault/openmediavault/raw/master/installer/install | sudo bash

# Access web UI
# http://<ip>
# Default login: admin / openmediavault

# Advantages:
# - Lighter than TrueNAS
# - Good plugin ecosystem
# - Familiar to Linux users

# Limitations:
# - No native ZFS support (requires workaround)
# - Smaller development community
```

### DIY Linux NAS

```bash
#!/bin/bash
set -euo pipefault

# Complete control but requires more setup
# Install Ubuntu Server + manual configuration

# Required packages
sudo apt-get update
sudo apt-get install -y \
    samba \
    nfs-kernel-server \
    zfs-initramfs \
    smartmontools \
    mdadm \
    htop \
    lm-sensors

# Manual approach gives you flexibility but requires
# understanding of: filesystems, RAID, networking, permissions
```

## Setting Up SMB/CIFS Shares

SMB (Server Message Block) is the protocol Windows uses for file sharing. It's also supported by macOS and Linux, making it universal for most homelabs.

### Install and Configure Samba

```bash
#!/bin/bash
set -euo pipefault

# Install Samba
sudo apt-get install -y samba samba-common-bin

# Backup original config
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Basic Samba configuration
sudo cat > /etc/samba/smb.conf <<'EOF'
[global]
    workgroup = WORKGROUP
    server string = Homelab NAS
    netbios name = HOMELAB-NAS
    dns proxy = no

    # Logging
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file

    # Security
    security = user
    map to guest = bad user
    guest account = nobody

    # Performance tuning
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
    read raw = yes
    write raw = yes
    getwd cache = yes

    # Disable printer sharing
    load printers = no
    printing = bsd
    printcap name = /dev/null
    disable spoolss = yes

# === SHARES ===

[media]
    comment = Media Library
    path = /mnt/nas/media
    browseable = yes
    read only = no
    guest ok = yes
    create mask = 0775
    directory mask = 0775

[backups]
    comment = VM and System Backups
    path = /mnt/nas/backups
    browseable = no
    read only = no
    valid users = @backup-users
    create mask = 0770
    directory mask = 0770

[personal]
    comment = Personal Files
    path = /mnt/nas/personal
    browseable = yes
    read only = no
    valid users = @personal-users
    create mask = 0700
    directory mask = 0700
EOF

# Create share directories
sudo mkdir -p /mnt/nas/{media,backups,personal}

# Set permissions
sudo chown nobody:nogroup /mnt/nas/media
sudo chmod 755 /mnt/nas/media

# Start Samba
sudo systemctl start smbd nmbd
sudo systemctl enable smbd nmbd

# Test configuration
sudo testparm -v

# Add Samba user (for authentication)
sudo smbpasswd -a username
```

### Create Additional Shares

```bash
#!/bin/bash
set -euo pipefault

# Function to add a share
add_samba_share() {
    local share_name="$1"
    local path="$2"
    local description="$3"
    local guest_ok="${4:-no}"

    # Create directory
    sudo mkdir -p "$path"
    sudo chown nobody:nogroup "$path"
    sudo chmod 755 "$path"

    # Add to smb.conf
    sudo tee -a /etc/samba/smb.conf > /dev/null <<EOF

[$share_name]
    comment = $description
    path = $path
    browseable = yes
    read only = no
    guest ok = $guest_ok
    create mask = 0775
    directory mask = 0775
EOF

    # Reload Samba
    sudo systemctl reload smbd
}

# Add shares
add_samba_share "downloads" "/mnt/nas/downloads" "Downloads" "yes"
add_samba_share "documents" "/mnt/nas/documents" "Shared Documents" "no"
add_samba_share "archive" "/mnt/nas/archive" "Old Files Archive" "no"
```

### Test SMB Access

```bash
#!/bin/bash
set -euo pipefault

NAS_IP="192.168.1.50"
USERNAME="nasusr"
PASSWORD="${SMB_PASSWORD}"  # Set from environment

# From Linux, test connection
sudo apt-get install -y smbclient cifs-utils

# List shares
smbclient -L //"$NAS_IP" -U "$USERNAME" -p 445 <<< "$PASSWORD"

# Mount share
sudo mkdir -p /mnt/nas-remote
sudo mount -t cifs \
    //"$NAS_IP"/media \
    /mnt/nas-remote \
    -o username="$USERNAME",password="$PASSWORD",uid=$UID,gid=$GID

# Test write
touch /mnt/nas-remote/test.txt

# Unmount
sudo umount /mnt/nas-remote
```

## Setting Up NFS Shares

NFS (Network File System) offers superior performance to SMB for Linux clients and is ideal for VM/container storage.

### Install and Configure NFS

```bash
#!/bin/bash
set -euo pipefault

# Install NFS server
sudo apt-get install -y nfs-kernel-server nfs-common

# Create NFS export directories
sudo mkdir -p /mnt/nas/{nfs-media,nfs-backups,nfs-vms}

# Configure NFS exports
sudo cat > /etc/exports <<'EOF'
# VM storage (restricted to homelab subnet, with caching disabled for safety)
/mnt/nas/nfs-vms 192.168.1.0/24(rw,sync,no_subtree_check,no_wdelay)

# Media library (read-heavy, can use async)
/mnt/nas/nfs-media 192.168.1.0/24(ro,sync,no_subtree_check)

# Backups (write-heavy, sync critical)
/mnt/nas/nfs-backups 192.168.1.0/24(rw,sync,no_subtree_check)
EOF

# Apply exports
sudo exportfs -a

# Enable and start NFS
sudo systemctl start nfs-server
sudo systemctl enable nfs-server

# Show exported shares
showmount -e localhost
```

### NFS Mount on Linux Client

```bash
#!/bin/bash
set -euo pipefact

NAS_IP="192.168.1.50"

# Install NFS client
sudo apt-get install -y nfs-common

# Create mount point
sudo mkdir -p /mnt/nfs-storage

# Mount NFS share
sudo mount -t nfs \
    -o rw,hard,intr,noatime,noac \
    "$NAS_IP":/mnt/nas/nfs-vms \
    /mnt/nfs-storage

# Check mount
mount | grep nfs

# Make persistent (add to /etc/fstab)
echo "$NAS_IP:/mnt/nas/nfs-vms /mnt/nfs-storage nfs rw,hard,intr,noatime,noac 0 0" | sudo tee -a /etc/fstab

# Test persistence
sudo umount /mnt/nfs-storage
sudo mount /mnt/nfs-storage
```

### NFS Performance Options

```bash
#!/bin/bash
set -euo pipefault

# Different mount options for different use cases:

# VM Storage (priority: reliability)
mount -t nfs -o rw,sync,hard,intr,noatime /nas:/nfs-vms /mnt/vms

# Media Library (priority: read speed)
mount -t nfs -o ro,async,hard,intr,nocto /nas:/nfs-media /mnt/media

# Backups (priority: reliability)
mount -t nfs -o rw,sync,hard,intr /nas:/nfs-backups /mnt/backups

# Home Directory (priority: responsiveness)
mount -t nfs -o rw,async,soft,intr,noatime /nas:/home /home

# Option explanations:
# sync: Write to disk before returning (reliable, slower)
# async: Return after caching (faster, less reliable)
# hard: Retry infinitely on failure (reliable)
# soft: Return error after timeout (responsive, may lose data)
# noatime: Don't update access time (performance)
# nocto: Don't cache file metadata (real-time consistency)
```

## User Permissions and Access Control

### Create NAS Users and Groups

```bash
#!/bin/bash
set -euo pipefalt

# Create system groups for NAS access
sudo groupadd -f media-users
sudo groupadd -f backup-users
sudo groupadd -f personal-users

# Create NAS user accounts
sudo useradd -m -s /usr/sbin/nologin nas-media
sudo useradd -m -s /usr/sbin/nologin nas-backup

# Add users to groups
sudo usermod -aG media-users nas-media
sudo usermod -aG backup-users nas-backup

# Set permissions on share directories
sudo chown -R nas-media:media-users /mnt/nas/media
sudo chmod 770 /mnt/nas/media

sudo chown -R nas-backup:backup-users /mnt/nas/backups
sudo chmod 770 /mnt/nas/backups
```

### SMB User Authentication

```bash
#!/bin/bash
set -euo pipefault

# Create Samba users (separate from system users)
# Use environment variables to avoid hardcoding passwords

# Add Samba user from environment
SAMBA_USER="homelab_user"
SAMBA_PASS="${SAMBA_PASSWORD}"  # Set from environment

# Create system user if needed
sudo useradd -s /usr/sbin/nologin "$SAMBA_USER" 2>/dev/null || true

# Create Samba password (non-interactive)
echo -e "$SAMBA_PASS\n$SAMBA_PASS" | sudo smbpasswd -a "$SAMBA_USER"

# Verify user
sudo pdbedit -L
```

### File and Directory Permissions

```bash
#!/bin/bash
set -euo pipefault

# Set umask for new files
umask 022  # New files: 644, new dirs: 755

# Set permissions on existing shares
# Media (everyone read, admins write)
sudo chmod 755 /mnt/nas/media
sudo chown -R nas-media:media-users /mnt/nas/media

# Backups (restricted access)
sudo chmod 750 /mnt/nas/backups
sudo chown -R nas-backup:backup-users /mnt/nas/backups

# Personal (private)
sudo chmod 700 /mnt/nas/personal
sudo chown $USER:$USER /mnt/nas/personal

# Set ACLs for fine-grained control
sudo setfacl -R -m u:nas-media:rwx /mnt/nas/media
sudo setfacl -R -m g:media-users:rx /mnt/nas/media
```

## RAID and ZFS Pool Planning

### RAID Levels Overview

| RAID | Drives | Capacity | Fault Tolerance | Use Case |
|------|--------|----------|-----------------|----------|
| **RAID 1** | 2 | 50% | 1 drive | Home server, small budget |
| **RAID 5** | 3+ | 67%+ | 1 drive | Sweet spot for homelabs |
| **RAID 6** | 4+ | 50%+ | 2 drives | Larger arrays, safety |
| **RAID 10** | 4+ | 50% | 1-2 drives | Performance-critical |

### Create RAID Array (mdadm)

```bash
#!/bin/bash
set -euo pipefault

# List available disks
sudo lsblk

# Create RAID 5 (3 drives, 1 spare recommended)
# /dev/sdb, /dev/sdc, /dev/sdd (plus /dev/sde as spare)

sudo mdadm --create /dev/md0 \
    --level=5 \
    --raid-devices=3 \
    --spare-devices=1 \
    /dev/sdb /dev/sdc /dev/sdd /dev/sde

# Monitor creation (takes time based on drive size)
sudo watch -n 1 'cat /proc/mdstat'

# Create filesystem on RAID array
sudo mkfs.ext4 /dev/md0

# Mount RAID array
sudo mkdir -p /mnt/raid
sudo mount /dev/md0 /mnt/raid

# Make persistent
sudo mdadm --detail --scan >> /etc/mdadm/mdadm.conf
echo "/dev/md0 /mnt/raid ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
```

### ZFS Pool Management (TrueNAS/ZFS)

```bash
#!/bin/bash
set -euo pipefault

# Create ZFS pool with RAID 5 (raidz)
sudo zpool create \
    -f \
    -o ashift=12 \
    -o autoexpand=on \
    storage \
    raidz \
    /dev/sdb \
    /dev/sdc \
    /dev/sdd

# Add spare
sudo zpool add storage spare /dev/sde

# Create datasets
sudo zfs create storage/media
sudo zfs create storage/backups
sudo zfs create storage/vms

# Set dataset compression
sudo zfs set compression=lz4 storage

# Enable snapshots
sudo zfs set com.sun:auto-snapshot=true storage/backups

# Check pool status
sudo zpool status -v
sudo zfs list -H -o name,used,available,mountpoint
```

## Performance Optimization

### Network Configuration

```bash
#!/bin/bash
set -euo pipefault

# Enable Jumbo Frames (9000 MTU) for higher throughput
# Requires all devices in path to support it

# Check current MTU
ip link show eth0

# Increase MTU (Netplan example for Ubuntu 20.04+)
sudo cat > /etc/netplan/02-jumbo-frames.yaml <<'EOF'
network:
  version: 2
  ethernets:
    eth0:
      mtu: 9000
EOF

sudo netplan apply

# Verify
ip link show eth0 | grep mtu
```

### SMB Optimization

```bash
#!/bin/bash
set -euo pipefault

# Add performance tuning to smb.conf
sudo cat >> /etc/samba/smb.conf <<'EOF'

[global]
    # SMB3 for better performance
    min protocol = SMB3
    max protocol = SMB3

    # I/O optimizations
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=262144 SO_SNDBUF=262144
    read raw = yes
    write raw = yes
    getwd cache = yes

    # Caching
    strict allocate = no
    load printers = no

    # Aio support
    aio read size = 16384
    aio write size = 16384
EOF

sudo systemctl restart smbd
```

### NFS Optimization

```bash
#!/bin/bash
set -euo pipefault

# NFS server tuning (/etc/default/nfs-kernel-server)
sudo cat >> /etc/default/nfs-kernel-server <<'EOF'

# Number of NFSD threads
RPCNFSDCOUNT=16

# NFS version support (v3 and v4 for compatibility)
RPCMOUNTDOPTS="-V 3 -V 4"

# TCP options
RPCNFSDOPTS="-U -V 3 -V 4"
EOF

sudo systemctl restart nfs-server
```

### Disk I/O Tuning

```bash
#!/bin/bash
set -euo pipefault

# Check current I/O scheduler
cat /sys/block/sda/queue/scheduler

# Use deadline or noop for NAS drives
echo "deadline" | sudo tee /sys/block/sda/queue/scheduler

# Make persistent (add to /etc/rc.local or systemd unit)
# For each disk: echo "deadline" > /sys/block/sdX/queue/scheduler
```

### Memory Caching

```bash
#!/bin/bash
set -euo pipefault

# Check available RAM
free -h

# Increase filesystem cache
# Add to /etc/sysctl.conf
echo "vm.dirty_ratio = 30" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio = 5" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

# Monitor cache usage
vmstat 1 10
```

## Monitoring Storage Health

### SMART Monitoring (Disk Health)

```bash
#!/bin/bash
set -euo pipefault

# Install smartmontools
sudo apt-get install -y smartmontools

# Enable SMART monitoring daemon
sudo systemctl enable smartd
sudo systemctl start smartd

# Run SMART test
sudo smartctl -a /dev/sda  # Long test
sudo smartctl -t long /dev/sda

# Monitor test progress
sudo smartctl -a /dev/sda | grep -i self-test

# Set up regular monitoring
cat > /tmp/monitor-disks.sh <<'EOF'
#!/bin/bash
set -euo pipefault

for disk in /dev/sda /dev/sdb /dev/sdc; do
    echo "=== Checking $disk ==="
    sudo smartctl -H "$disk"
    sudo smartctl -a "$disk" | grep -i temperature
done
EOF

chmod +x /tmp/monitor-disks.sh

# Add to crontab for daily checks
# 0 2 * * * /tmp/monitor-disks.sh >> /var/log/disk-health.log
```

### RAID Status Monitoring

```bash
#!/bin/bash
set -euo pipefaft

# Check RAID status
sudo cat /proc/mdstat

# Monitor specific array
sudo mdadm --detail /dev/md0

# Set up alerts for RAID failures
sudo cat > /usr/local/bin/raid-monitor.sh <<'EOF'
#!/bin/bash
set -euo pipefault

STATUS=$(cat /proc/mdstat)

if echo "$STATUS" | grep -q "U_\|_U"; then
    echo "RAID degraded!" | mail -s "RAID Alert" admin@example.com
fi
EOF

chmod +x /usr/local/bin/raid-monitor.sh

# Add to crontab
# 0 * * * * /usr/local/bin/raid-monitor.sh
```

### Disk Space Monitoring

```bash
#!/bin/bash
set -euo pipefault

# Monitor disk usage
df -h

# Show largest directories
du -sh /mnt/nas/* | sort -hr

# Set up quota alerts
cat > /usr/local/bin/check-disk-usage.sh <<'EOF'
#!/bin/bash
set -euo pipefault

THRESHOLD=90

for fs in /mnt/nas/*; do
    usage=$(df "$fs" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt $THRESHOLD ]]; then
        echo "Storage alert: $fs is ${usage}% full"
    fi
done
EOF

chmod +x /usr/local/bin/check-disk-usage.sh

# Add to crontab for hourly checks
# 0 * * * * /usr/local/bin/check-disk-usage.sh
```

## Backup Integration

### NAS as Backup Destination

```bash
#!/bin/bash
set -euo pipefault

# Create backup schedule
cat > /usr/local/bin/backup-to-nas.sh <<'EOF'
#!/bin/bash
set -euo pipefault

NAS_IP="192.168.1.50"
NAS_SHARE="/mnt/nas/backups"
BACKUP_SOURCE="/"
BACKUP_EXCLUDE="/proc,/sys,/dev,/run,/mnt,/media"

# Mount NAS
sudo mount -t nfs "$NAS_IP:$NAS_SHARE" /mnt/nas-backup

# Backup VMs
for vm in /var/lib/libvirt/images/*.qcow2; do
    echo "Backing up $(basename $vm)"
    sudo cp "$vm" /mnt/nas-backup/
done

# Backup configs
sudo tar czf /mnt/nas-backup/configs-$(date +%Y%m%d).tar.gz \
    /etc /root/.ssh /root/.config 2>/dev/null || true

# Unmount
sudo umount /mnt/nas-backup
EOF

chmod +x /usr/local/bin/backup-to-nas.sh

# Add to crontab for daily backups
# 2 * * * * /usr/local/bin/backup-to-nas.sh >> /var/log/backups.log
```

### Backup Retention Policy

```bash
#!/bin/bash
set -euo pipefault

# Clean up old backups
BACKUP_DIR="/mnt/nas/backups"
RETENTION_DAYS=30

# Delete backups older than retention period
find "$BACKUP_DIR" -type f -mtime "+$RETENTION_DAYS" -delete

# List backup space usage
du -sh "$BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -20
```

## Troubleshooting Common Issues

### SMB Share Not Accessible

```bash
#!/bin/bash
set -euo pipefault

# Test Samba configuration
sudo testparm -v

# Check Samba running
sudo systemctl status smbd nmbd

# Test connectivity
smbclient -L //<nas-ip> -U username

# Check firewall
sudo ufw allow 445/tcp  # SMB port
sudo ufw allow 137:139/udp  # NetBIOS ports

# View Samba logs
sudo tail -f /var/log/samba/log.smbd
```

### NFS Mount Failing

```bash
#!/bin/bash
set -euo pipefault

# Verify NFS exports
showmount -e <nas-ip>

# Check NFS running
sudo systemctl status nfs-server

# Test connectivity
sudo nfsstat

# Check firewall
sudo ufw allow 111/tcp  # Portmapper
sudo ufw allow 2049/tcp # NFS
sudo ufw allow 2049/udp

# Try remount
sudo umount /mnt/nfs 2>/dev/null || true
sudo mount -t nfs <nas-ip>:/export /mnt/nfs
```

### Slow Performance

```bash
#!/bin/bash
set -euo pipefault

# Monitor network utilization
iftop -n

# Monitor disk I/O
iostat -x 1

# Check for network issues
ping -c 10 <nas-ip>  # Look for latency
iperf3 -c <nas-ip>   # Measure throughput

# Monitor NFS performance
nfsstat -s
nfsstat -c

# Check for slow disk issues
sudo fio --name=benchmark --filename=/mnt/test \
    --rw=read --bs=4k --numjobs=4 --size=1G
```

### Disk Failure Handling

```bash
#!/bin/bash
set -euo pipefaft

# For RAID arrays
# Check status
sudo mdadm --detail /dev/md0

# Remove failed disk
sudo mdadm /dev/md0 --fail /dev/sdd
sudo mdadm /dev/md0 --remove /dev/sdd

# Add replacement (same size or larger)
sudo mdadm /dev/md0 --add /dev/sde

# Monitor rebuild
watch -n 1 'cat /proc/mdstat'

# For ZFS
# Check pool status
sudo zpool status -v storage

# Replace failed device
sudo zpool replace storage <old-device> <new-device>

# Monitor resilver
watch -n 1 'zpool status storage'
```

## Best Practices

1. **Plan for Growth** - Use RAID 5 or 6, not just RAID 1
2. **Multiple Backups** - NAS is not a backup, back up your NAS
3. **Monitor Proactively** - Use SMART monitoring and alerts
4. **Separate Concerns** - Different shares for different purposes
5. **Documented Access** - Keep clear records of users/permissions
6. **Regular Testing** - Test restore procedures from backups
7. **Keep Updated** - Regular OS and package updates
8. **Adequate Cooling** - 24/7 operation requires good airflow
9. **Redundant Power** - Consider UPS for unexpected shutdowns
10. **Off-site Copies** - Critical backups should leave the house

## Additional Resources

- [TrueNAS Documentation](https://www.truenas.com/docs/)
- [OpenMediaVault Documentation](https://docs.openmediavault.org/)
- [Samba Documentation](https://wiki.samba.org/)
- [NFS Documentation](https://wiki.linux-nfs.org/)
- [ZFS Documentation](https://openzfs.org/)
- [RAID Guide](https://en.wikipedia.org/wiki/Standard_RAID_levels)
- [SMART Monitoring](https://wiki.archlinux.org/title/S.M.A.R.T.)

---

✅ **You now have a comprehensive NAS setup with proper storage, sharing, monitoring, and backup strategies for your homelab!**
