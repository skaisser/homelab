# 🚨 Disaster Recovery Procedures #backup #disaster-recovery #restore #procedures

Develop a comprehensive disaster recovery plan to restore your homelab quickly from backups. This guide covers recovery strategies, procedures, and testing.

## Table of Contents

1. [DR Planning Fundamentals](#dr-planning-fundamentals)
2. [Infrastructure Documentation](#infrastructure-documentation)
3. [Recovery Priority Order](#recovery-priority-order)
4. [Bare Metal Recovery](#bare-metal-recovery)
5. [VM Restoration](#vm-restoration)
6. [Container Restoration](#container-restoration)
7. [Data Restoration](#data-restoration)
8. [Network Recovery](#network-recovery)
9. [Testing Recovery](#testing-recovery)
10. [DR Checklist](#dr-checklist)
11. [Post-Recovery Verification](#post-recovery-verification)

## DR Planning Fundamentals

### Define RPO and RTO

- **Recovery Time Objective (RTO):** Maximum acceptable time to restore service
  - Tier 1 (critical): 1-2 hours
  - Tier 2 (important): 4-6 hours
  - Tier 3 (standard): 24 hours

- **Recovery Point Objective (RPO):** Maximum acceptable data loss
  - Tier 1: Hourly backups
  - Tier 2: Daily backups
  - Tier 3: Weekly backups

### DR Plan Template

```bash
# Create DR documentation
cat > /home/user/homelab-dr-plan.txt << 'EOF'
# Homelab Disaster Recovery Plan

## RTO/RPO Targets
- Domain controller: RTO 1h, RPO 1h
- File server: RTO 2h, RPO 6h
- Media server: RTO 24h, RPO 24h
- Development VM: RTO 24h, RPO daily

## Backup Locations
- Local NAS: /mnt/nas-backup/homelab
- Cloud: B2 bucket "homelab-offsite"
- USB rotation: Encrypted external drive

## Contact Information
- Primary admin: user@example.com
- Secondary: backup-admin@example.com
- Network ISP support: [phone/ticket]

## Recovery Hardware
- Spare system: [details]
- Recovery media: [location]
- Network equipment spares: [inventory]
EOF

chmod 600 /home/user/homelab-dr-plan.txt
```

## Infrastructure Documentation

### Document Your Infrastructure

```bash
# Create system inventory
cat > /home/user/homelab-inventory.txt << 'EOF'
# Homelab Inventory

## Hardware
- Host 1: Dell R640, 2x CPU, 256GB RAM, 20TB storage
- Host 2: HP Microserver, 1x CPU, 32GB RAM, 5TB storage
- NAS: Synology DS920+, 16TB RAID6
- Network: Ubiquiti EdgeRouter, Unifi AP Pro

## VMs/Containers
- dc1.home: Windows Domain Controller
  - IP: 192.168.1.10
  - Backup: Daily to NAS
  - Critical apps: AD, DNS

- plex.home: Plex Media Server
  - IP: 192.168.1.20
  - Backup: Weekly to NAS
  - Data: /opt/plex (500GB)

## Network Configuration
- LAN: 192.168.1.0/24
  - Gateway: 192.168.1.1
  - DNS: 192.168.1.10
  - DHCP: 192.168.1.100-200

- VLAN100: 10.0.100.0/24 (Management)
EOF
```

### Document Passwords Securely

```bash
# Create encrypted password file
gpg --symmetric --cipher-algo AES256 << 'EOF' > ~/.homelab-creds.gpg
# Homelab Credentials

IPMI Root: root / [password]
NAS Admin: admin / [password]
VM Templates: user / [password]
Cloud B2: account_id / app_key
EOF

chmod 600 ~/.homelab-creds.gpg
```

## Recovery Priority Order

### Prioritize Recovery Sequence

```bash
#!/bin/bash
# Recovery priority script

PRIORITY_ORDER=(
    "192.168.1.10|dc1.home|Domain Controller|RTO: 1h"
    "192.168.1.20|plex.home|File Server|RTO: 2h"
    "192.168.1.30|app1.home|Web App|RTO: 4h"
    "192.168.1.40|dev1.home|Dev VM|RTO: 24h"
)

echo "Recovery Priority Order:"
echo "========================"
for ((i=0; i<${#PRIORITY_ORDER[@]}; i++)); do
    IFS='|' read -r ip hostname service rto <<< "${PRIORITY_ORDER[$i]}"
    echo "$((i+1)). $hostname ($ip) - $service"
    echo "   $rto"
    echo ""
done
```

## Bare Metal Recovery

### Create System Recovery Image

```bash
# Install clonezilla
sudo apt-get install clonezilla

# Create recovery media
sudo dd if=clonezilla.iso of=/dev/sdX bs=4M status=progress

# OR use ddrescue for safer imaging
sudo apt-get install gddrescue
sudo ddrescue --force /dev/sda /mnt/backup/system-image.img
```

### Boot and Restore

```bash
# Boot from recovery media (USB/PXE)
# Follow Clonezilla GUI to restore from image

# Or command-line restore
sudo ddrescue /mnt/backup/system-image.img /dev/sda
sync
reboot
```

### System Configuration Backup

```bash
#!/bin/bash
# Backup critical system configuration

BACKUP_DIR="/mnt/backup/system-config"
mkdir -p "$BACKUP_DIR"

# Backup network configuration
sudo cp -r /etc/netplan "$BACKUP_DIR/"
sudo cp -r /etc/network "$BACKUP_DIR/"

# Backup system files
sudo cp -r /etc/hosts "$BACKUP_DIR/"
sudo cp -r /etc/resolv.conf "$BACKUP_DIR/"
sudo cp -r /etc/hostname "$BACKUP_DIR/"

# Backup fstab and other critical configs
sudo cp /etc/fstab "$BACKUP_DIR/"
sudo cp /etc/crypttab "$BACKUP_DIR/"

# Make readable by user
sudo chown -R $USER:$USER "$BACKUP_DIR"
```

## VM Restoration

### Proxmox VM Recovery

```bash
# List available backups
proxmox-backup-client list --repository pbs:local

# Restore VM from PBS backup
proxmox-backup-client restore vm_backup pbs:vm-id-2026-03-12T10:00:00 --restore-original-job

# Or manually
# 1. Download backup from PBS
proxmox-backup-client download --repository pbs:local \
    vm/vm-id/2026-03-12T10:00:00/vm-disk-disk1.dat.fidx /mnt/restore/

# 2. Import backup to Proxmox
qm importdisk 100 /mnt/restore/vm-disk-disk1.dat local
```

### QEMU/KVM VM Recovery

```bash
# Restore VM disk from backup
restic -r /mnt/backup/restic-repo restore latest \
    --target /var/lib/libvirt/images \
    --include '/var/lib/libvirt/images/vm-name.qcow2'

# Verify VM disk
qemu-img check /var/lib/libvirt/images/vm-name.qcow2

# Restore VM XML configuration
restic -r /mnt/backup/restic-repo restore latest \
    --target /tmp \
    --include '/etc/libvirt/qemu/vm-name.xml'

sudo cp /tmp/etc/libvirt/qemu/vm-name.xml /etc/libvirt/qemu/
sudo virsh define /etc/libvirt/qemu/vm-name.xml
sudo virsh start vm-name
```

### VirtualBox VM Recovery

```bash
# Restore VM files
restic -r /mnt/backup/restic-repo restore latest \
    --target /home/user/VirtualBox\ VMs

# Verify and import
VBoxManage registervm "/home/user/VirtualBox VMs/vm-name/vm-name.vbox"

# Start VM
VBoxManage startvm vm-name
```

## Container Restoration

### Docker Container Recovery

```bash
# Restore Docker volumes from backup
docker volume create restored-volume
docker run -v /mnt/backup/docker-volumes/important:/backup \
    -v restored-volume:/restore \
    alpine cp -r /backup /restore

# Or restore entire Docker config
rsync -av /mnt/backup/docker/ /var/lib/docker/

# Restore Docker Compose configuration
restic -r /mnt/backup/restic-repo restore latest \
    --target /tmp \
    --include '/opt/docker-compose'

docker-compose -f /tmp/opt/docker-compose/docker-compose.yml up -d
```

### Kubernetes Recovery

```bash
# Restore etcd backup
ETCDCTL_API=3 etcdctl snapshot restore /mnt/backup/etcd-backup.db \
    --data-dir /var/lib/etcd-restored

# Verify restoration
ETCDCTL_API=3 etcdctl --data-dir /var/lib/etcd-restored member list

# Restore Kubernetes manifests
kubectl apply -f /mnt/backup/k8s-manifests/
```

## Data Restoration

### Restore Files from Backup

```bash
# From rsync backup
cp -r /mnt/backup/home/user/important /restore/location

# From restic
restic -r /mnt/backup/restic-repo restore latest \
    --target /restore/location \
    --include '/home/user/important'

# From BorgBackup
borg extract /mnt/backup/borg-repo::hostname-2026-03-12 \
    home/user/important
```

### Database Recovery

```bash
# MySQL/MariaDB recovery
restic -r /mnt/backup/restic-repo restore latest \
    --target /tmp \
    --include 'mysql-backup.sql'

mysql -u root -p < /tmp/mysql-backup.sql

# PostgreSQL recovery
pg_restore -U postgres -d database /mnt/backup/postgres-backup.dump

# MongoDB recovery
mongorestore --archive=/mnt/backup/mongodb-backup.archive
```

## Network Recovery

### Restore Network Configuration

```bash
# Restore network interfaces
sudo cp /mnt/backup/system-config/netplan/* /etc/netplan/
sudo netplan apply

# Verify connectivity
ping -c 3 8.8.8.8
nslookup google.com

# Restore DNS configuration
sudo cp /mnt/backup/system-config/resolv.conf /etc/
```

### Restore Network Services

```bash
# Restore DHCP configuration
sudo cp /mnt/backup/system-config/dhcpd.conf /etc/dhcp/
sudo systemctl restart isc-dhcp-server

# Restore DNS (BIND9)
sudo cp /mnt/backup/system-config/bind/* /etc/bind/
sudo systemctl restart bind9

# Verify services
systemctl status isc-dhcp-server
systemctl status bind9
```

## Testing Recovery

### Create Test Recovery Plan

```bash
#!/bin/bash
# Test recovery procedure

TEST_DIR="/tmp/recovery-test-$(date +%Y%m%d)"
mkdir -p "$TEST_DIR"

echo "Starting recovery test..."
echo "Test directory: $TEST_DIR"

# Test 1: Restore from restic
echo "Test 1: Restic restore"
restic -r /mnt/backup/restic-repo restore latest --target "$TEST_DIR/restic-test"
echo "Files restored: $(find $TEST_DIR/restic-test -type f | wc -l)"

# Test 2: Verify integrity
echo "Test 2: Integrity check"
find "$TEST_DIR/restic-test" -type f -exec md5sum {} \; > "$TEST_DIR/restore-checksums.md5"

# Test 3: Database restore
echo "Test 3: Database restore"
mysql -u root -p < "$TEST_DIR/mysql-backup.sql"

# Cleanup
echo "Test complete, cleaning up..."
rm -rf "$TEST_DIR"
```

### Monthly Recovery Test Schedule

```bash
# /etc/systemd/system/recovery-test.timer
[Unit]
Description=Monthly Recovery Test
Requires=recovery-test.service

[Timer]
OnCalendar=monthly
OnCalendar=*-*-01 02:00:00

[Install]
WantedBy=timers.target
```

## DR Checklist

### Pre-Disaster Preparation

```bash
cat > /home/user/dr-checklist.md << 'EOF'
# Disaster Recovery Checklist

## Before Disaster
- [ ] Backup strategy documented and tested
- [ ] RTO/RPO defined for each system
- [ ] Passwords stored securely and accessible
- [ ] Recovery procedures documented
- [ ] Recovery hardware identified and tested
- [ ] Network diagram and IP allocation documented
- [ ] VM templates and boot media prepared
- [ ] Recovery tests completed monthly

## During Disaster
- [ ] Declare disaster and activate DR team
- [ ] Notify stakeholders of status
- [ ] Assess damage and data loss
- [ ] Begin recovery in priority order
- [ ] Document all recovery actions
- [ ] Verify restored systems

## After Disaster
- [ ] Verify all services restored
- [ ] Run integrity checks on all data
- [ ] Document lessons learned
- [ ] Update DR procedures
- [ ] Schedule recovery tests again
EOF
```

## Post-Recovery Verification

### Verify System Functionality

```bash
#!/bin/bash
# Post-recovery verification script

echo "Post-Recovery Verification"
echo "==========================="

# Check network
echo "1. Network connectivity:"
ping -c 1 8.8.8.8 && echo "✓ Internet access" || echo "✗ Internet access FAILED"

# Check DNS
echo "2. DNS resolution:"
nslookup google.com && echo "✓ DNS working" || echo "✗ DNS FAILED"

# Check services
echo "3. Critical services:"
for service in ssh postgresql mysql redis; do
    systemctl is-active $service > /dev/null && echo "✓ $service running" || echo "✗ $service FAILED"
done

# Check disk space
echo "4. Disk space:"
df -h / | tail -1

# Check backups
echo "5. Backup accessibility:"
test -r /mnt/backup && echo "✓ Backups accessible" || echo "✗ Backups not accessible"
```

### Data Integrity Verification

```bash
# Verify checksums
sha256sum -c /mnt/backup/checksums.sha256

# Database consistency
mysql -e "CHECK TABLE \`database\`.*;"
pg_dump --schema-only database > /tmp/schema-check.sql

# Log verification
grep -i error /var/log/syslog | tail -20
```

---

✅ Create documented DR plan, test recovery procedures quarterly, maintain accessibility of recovery documentation
