# 🔄 System Updates and Patch Management #maintenance #updates #apt #security-patches

Develop a safe, systematic approach to applying updates in your homelab while minimizing downtime and maintaining stability.

## Table of Contents

1. [Update Strategy](#update-strategy)
2. [apt Update Workflow](#apt-update-workflow)
3. [Security Patches](#security-patches)
4. [Unattended Upgrades](#unattended-upgrades)
5. [Proxmox Updates](#proxmox-updates)
6. [Docker Image Updates](#docker-image-updates)
7. [Checking Changelogs](#checking-changelogs)
8. [Rollback Strategies](#rollback-strategies)
9. [Maintenance Windows](#maintenance-windows)
10. [Troubleshooting](#troubleshooting)

## Update Strategy

### Update Tiering

```bash
# Tier 1: Critical security patches (apply ASAP)
# - OS kernel vulnerabilities
# - Database security patches
# - Network service vulnerabilities

# Tier 2: Regular updates (weekly)
# - Non-critical security patches
# - Package updates
# - Application updates

# Tier 3: Major version upgrades (quarterly)
# - OS version upgrades
# - Major software versions
# - Framework upgrades

# Document your strategy
cat > /home/user/update-strategy.txt << 'EOF'
# Update Management Strategy

## Critical Patches
- Applied immediately on test system first
- RTO: 24-48 hours to production

## Regular Updates
- Applied weekly to test systems
- Move to production Friday evening
- Revert if issues detected over weekend

## Major Upgrades
- Planned quarterly
- Executed during maintenance window
- Scheduled backup beforehand
EOF
```

## apt Update Workflow

### Check Available Updates

```bash
# Update package cache
sudo apt-get update

# List upgradeable packages
apt list --upgradable

# Show detailed update information
apt-cache policy package-name

# Show changelog before updating
apt-get changelog package-name | less
```

### Apply Updates Safely

```bash
# Test updates on non-critical system first
# On test system:
sudo apt-get upgrade

# Review changes
apt list --upgradable

# On production systems (after successful test):
sudo apt-get upgrade

# For kernel or major package updates:
sudo apt-get dist-upgrade
```

### Update Specific Packages

```bash
# Update single package
sudo apt-get install --only-upgrade postgresql

# Update package group
sudo apt-get install --only-upgrade gcc g++ build-essential

# Avoid version locks with specific hold
sudo apt-mark hold postgresql
sudo apt-mark unhold postgresql
```

### Complete Update Workflow

```bash
#!/bin/bash
# Safe update procedure

set -e  # Exit on any error

BACKUP_SNAPSHOT="backup-pre-update-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/var/log/update-$(date +%Y%m%d-%H%M%S).log"

echo "[$(date)] Starting system update" > "$LOG_FILE"

# Step 1: Backup current state
echo "[$(date)] Creating snapshot..." | tee -a "$LOG_FILE"
sudo zfs snapshot tank/root@$BACKUP_SNAPSHOT

# Step 2: Update package cache
echo "[$(date)] Updating package cache..." | tee -a "$LOG_FILE"
sudo apt-get update 2>&1 | tee -a "$LOG_FILE"

# Step 3: Preview changes
echo "[$(date)] Upgradeable packages:" | tee -a "$LOG_FILE"
apt list --upgradable 2>&1 | tee -a "$LOG_FILE"

# Step 4: Install upgrades
echo "[$(date)] Installing updates..." | tee -a "$LOG_FILE"
sudo apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"

# Step 5: Clean up
echo "[$(date)] Cleaning up..." | tee -a "$LOG_FILE"
sudo apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo apt-get autoclean 2>&1 | tee -a "$LOG_FILE"

# Step 6: Reboot if kernel updated
if grep -q "linux-image" "$LOG_FILE"; then
    echo "[$(date)] Kernel updated, rebooting in 5 minutes..." | tee -a "$LOG_FILE"
    sudo shutdown -r +5
else
    echo "[$(date)] Update complete, no reboot needed" | tee -a "$LOG_FILE"
fi

chmod 600 "$LOG_FILE"
```

## Security Patches

### Security Patch Monitoring

```bash
# Subscribe to security advisories
sudo apt-get install apt-listchanges

# Configure security alerts
sudo apt-get install debian-goodies
checkupdates

# Set up unattended-upgrades for security patches
sudo apt-get install unattended-upgrades apt-listchanges
```

### Apply Security Patches Priority

```bash
# Check for security updates only
sudo apt list --upgradable | grep -i security

# Or with more detail
sudo unattended-upgrade --dry-run -d

# Apply security patches only (safer than full upgrades)
sudo unattended-upgrade -d
```

### CVE Vulnerability Checking

```bash
# Install vulnerability scanner
pip3 install safety bandit

# Check Python packages for vulnerabilities
safety check

# Check code for common security issues
bandit -r /opt/myapp

# Ubuntu CVE tracker
# Visit: https://ubuntu.com/security/notices
```

## Unattended Upgrades

### Install and Configure

```bash
# Install unattended-upgrades
sudo apt-get install unattended-upgrades apt-listchanges

# Enable the service
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Configuration

```bash
# Edit: /etc/apt/apt.conf.d/50unattended-upgrades

# Only security patches
sudo sed -i 's|"${distro_id}:${distro_codename}-updates";|// "${distro_id}:${distro_codename}-updates";|' /etc/apt/apt.conf.d/50unattended-upgrades

# Email notifications
sudo sed -i 's/^\/\/ *Unattended-Upgrade::Mail "/Unattended-Upgrade::Mail "root@example.com"/' /etc/apt/apt.conf.d/50unattended-upgrades

# Auto-reboot if needed
echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot-Time "03:00";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
```

### Verify Configuration

```bash
# Test unattended-upgrade
sudo unattended-upgrade --dry-run -d

# Check if scheduled correctly
systemctl is-enabled apt-daily-upgrade.timer
systemctl status apt-daily-upgrade.timer

# View update logs
journalctl -u apt-daily-upgrade -e
```

## Proxmox Updates

### Check Proxmox Updates

```bash
# List available updates
apt list --upgradable

# Check for new Proxmox kernel
apt list --upgradable | grep pve-kernel
```

### Update Proxmox Nodes

```bash
# Single node update (with minimal downtime)
sudo apt-get update
sudo apt-get upgrade

# Check if reboot needed
sudo needrestart -r a

# For cluster: drain node first
sudo pct list  # List VMs
# Migrate VMs to other nodes
sudo pct migrate 100 pve-node2

# Then reboot
sudo shutdown -r now
```

### Update Proxmox Web Interface

```bash
# Proxmox typically updates with system packages
sudo apt-get upgrade

# Verify
sudo systemctl restart pveproxy pvedaemon
curl https://localhost:8006

# Check version
pveversion
```

## Docker Image Updates

### Manual Docker Updates

```bash
# Update base images
docker pull ubuntu:22.04
docker pull nginx:latest

# Rebuild containers with new images
docker-compose down
docker-compose pull
docker-compose up -d
```

### Watchtower Automation

```bash
# Install Watchtower for automatic container updates
docker run -d \
    --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e WATCHTOWER_SCHEDULE="0 0 2 * * *" \
    -e WATCHTOWER_CLEANUP=true \
    containrrr/watchtower

# Configuration with docker-compose
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_SCHEDULE=0 0 2 * * *
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=true
    restart: unless-stopped
EOF

docker-compose up -d
```

### Check Image Updates

```bash
# List available image updates
docker ps -a --format "table {{.Image}}" | sort -u | while read image; do
    echo "Checking: $image"
    docker pull "$image" --quiet 2>/dev/null && echo "✓ Updated" || echo "✗ Latest"
done
```

## Checking Changelogs

### View Package Changelogs

```bash
# Install tools for changelog viewing
sudo apt-get install apt-listchanges

# View changelog for specific package
apt-get changelog nginx

# View changelog in less pager
apt-get changelog postgresql | less

# Search for specific issues in changelog
apt-get changelog mypackage | grep -A 2 "security"
```

### Check Upstream Releases

```bash
# Check GitHub releases
curl -s https://api.github.com/repos/owner/repo/releases | jq '.[] | .tag_name, .body'

# Check Docker Hub for image updates
curl -s https://registry.hub.docker.com/v2/library/nginx/manifests/latest | jq '.config.digest'

# Check official websites
# nginx: http://nginx.org/en/download.html
# PostgreSQL: https://www.postgresql.org/support/
```

## Rollback Strategies

### Rollback with ZFS Snapshots

```bash
# Before major update, create snapshot
sudo zfs snapshot tank/root@before-upgrade

# If issues occur, rollback
sudo zfs rollback tank/root@before-upgrade

# Verify rollback
zfs list -t snapshot
```

### Rollback apt Changes

```bash
# View apt history
cat /var/log/apt/history.log

# Check what was upgraded
grep "Upgrade:" /var/log/apt/history.log

# Downgrade specific package
sudo apt-get install package-name=old-version

# Or downgrade all to specific date
sudo apt-get install debian-goodies
sudo apt-get upgrade  # Then selectively downgrade packages
```

### Docker Rollback

```bash
# Keep previous image
docker pull app:v1.0
docker pull app:v1.1

# Run v1.0 if v1.1 fails
docker-compose down
docker tag app:v1.0 app:latest
docker-compose up -d

# Remove broken image
docker rmi app:v1.1
```

## Maintenance Windows

### Schedule Maintenance Window

```bash
# Document maintenance schedule
cat > /home/user/maintenance-schedule.txt << 'EOF'
# Maintenance Windows

## Weekly Security Updates
- Friday 22:00 to Sunday 02:00 UTC
- Test systems: Wednesday evening
- Production: Friday after testing

## Monthly Patching
- First Saturday: 20:00 UTC (4 hours)
- All non-critical systems
- Backup before starting

## Quarterly Major Upgrades
- Scheduled 2 weeks in advance
- 8-hour maintenance window
- Full backup required
EOF
```

### Notify Users Before Maintenance

```bash
#!/bin/bash
# Notify users of upcoming maintenance

MAINTENANCE_TIME="Friday 22:00"
MAINTENANCE_HOURS=2

echo "MAINTENANCE NOTIFICATION" | mail -s "Scheduled maintenance: $MAINTENANCE_TIME" users@example.com << EOF
Dear Users,

We will be performing system maintenance this Friday.

Date: Friday, March 14, 2026
Time: 22:00 - 00:00 UTC
Duration: $MAINTENANCE_HOURS hours

During this time, the following services will be unavailable:
- [List services]

Please plan accordingly. For questions, contact: admin@example.com

Thank you,
IT Team
EOF
```

## Troubleshooting

### Issue: Update fails with dependency errors
```bash
# Fix broken dependencies
sudo apt-get --fix-broken install

# Try upgrade with auto-fixing
sudo apt-get -f upgrade

# Use aptitude for advanced resolution
sudo apt-get install aptitude
sudo aptitude safe-upgrade
```

### Issue: Unattended-upgrades not running
```bash
# Check if service is enabled
systemctl is-enabled apt-daily-upgrade.timer

# View logs
journalctl -u apt-daily-upgrade -n 50

# Manual trigger
sudo systemctl start apt-daily-upgrade.service

# Check for conflicts
systemctl list-timers
```

### Issue: Kernel update causes boot failure
```bash
# Boot into grub menu at startup
# Select previous kernel version
# Once booted, remove problematic kernel
sudo apt-get remove linux-image-5.x.x-generic

# Or restore from ZFS snapshot
sudo zfs rollback tank/root@before-upgrade
```

---

✅ Implement tiered update strategy with security priority, automate non-critical patches, test major updates before production
