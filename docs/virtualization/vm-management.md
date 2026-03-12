# 🎛️ VM Administration Best Practices #virtualization #management #administration #best-practices

Effective VM administration is crucial for a stable homelab. This guide covers lifecycle management, resource allocation strategies, backup and recovery procedures, performance monitoring, and automation techniques that will keep your virtual environment running smoothly and efficiently.

## Table of Contents

- [VM Lifecycle Management](#vm-lifecycle-management)
- [Resource Allocation Strategies](#resource-allocation-strategies)
- [Template Creation and Cloning](#template-creation-and-cloning)
- [Snapshot Management and Policies](#snapshot-management-and-policies)
- [Backup Strategies for VMs](#backup-strategies-for-vms)
- [Monitoring VM Performance](#monitoring-vm-performance)
- [Automation with virsh and qm](#automation-with-virsh-and-qm)
- [Naming Conventions and Organization](#naming-conventions-and-organization)
- [Documentation Practices](#documentation-practices)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Best Practices Summary](#best-practices-summary)
- [Additional Resources](#additional-resources)

## VM Lifecycle Management

### Complete VM Lifecycle Workflow

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="${1:-test-vm}"
ACTION="${2:-status}"  # status, deploy, pause, resume, retire

case "$ACTION" in
    status)
        echo "=== VM Status: $VM_NAME ==="
        virsh dominfo "$VM_NAME"
        virsh domstats "$VM_NAME" --cpu --memory
        ;;
    deploy)
        echo "Deploying $VM_NAME..."
        virsh start "$VM_NAME"
        sleep 5
        virsh dominfo "$VM_NAME"
        ;;
    pause)
        echo "Pausing $VM_NAME..."
        virsh suspend "$VM_NAME"
        ;;
    resume)
        echo "Resuming $VM_NAME..."
        virsh resume "$VM_NAME"
        ;;
    retire)
        echo "WARNING: This will shut down and remove $VM_NAME"
        read -p "Continue? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            virsh destroy "$VM_NAME" 2>/dev/null || true
            virsh undefine "$VM_NAME" --remove-all-storage
        fi
        ;;
    *)
        echo "Unknown action: $ACTION"
        ;;
esac
```

### Resource Allocation Strategies

Different VM types need different resources:

```bash
#!/bin/bash
set -euo pipefail

# === Development VM ===
# CPU: 2 vCPUs, RAM: 2-4GB, Disk: 20GB
virt-install \
    --name dev-vm \
    --memory 2048 \
    --vcpus 2 \
    --disk size=20 \
    --network bridge=br0

# === Database Server ===
# CPU: 4-8 vCPUs, RAM: 8-16GB, Disk: 100GB+ (fast storage)
virt-install \
    --name db-server \
    --memory 8192 \
    --vcpus 4 \
    --disk size=100,format=qcow2 \
    --network bridge=br0

# === Web Server ===
# CPU: 2-4 vCPUs, RAM: 4-8GB, Disk: 40GB
virt-install \
    --name web-server \
    --memory 4096 \
    --vcpus 2 \
    --disk size=40 \
    --network bridge=br0

# === Desktop/GUI VM ===
# CPU: 4 vCPUs, RAM: 4-8GB, Disk: 40-60GB, Graphics: SPICE/VNC
virt-install \
    --name desktop-vm \
    --memory 4096 \
    --vcpus 4 \
    --disk size=50 \
    --graphics spice \
    --network bridge=br0
```

### Adjusting Resources on Running VMs

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="web-server"

# Increase RAM (must be offline or use balloning if supported)
virsh setmem "$VM_NAME" 8192000 --config  # Persistent change
virsh setmem "$VM_NAME" 8192000 --live    # Temporary change

# Increase vCPU count
virsh setvcpus "$VM_NAME" 4 --config --maximum  # Set max vCPUs
virsh setvcpus "$VM_NAME" 4 --live --current   # Apply to running VM

# Check current allocation
virsh dominfo "$VM_NAME"
```

## Template Creation and Cloning

### Create a Master Template

```bash
#!/bin/bash
set -euo pipefail

# Create a minimal, well-configured base VM
virt-install \
    --name ubuntu-template \
    --memory 2048 \
    --vcpus 2 \
    --disk size=30,format=qcow2 \
    --cdrom ~/isos/ubuntu-22.04-server-amd64.iso \
    --network bridge=br0 \
    --noautoconsole

# After installation, configure:
# 1. System updates
# 2. Essential packages (openssh-server, curl, etc.)
# 3. Cloud-init (for automation)
# 4. Hardened security settings
# 5. Shutdown and mark as template

virsh shutdown ubuntu-template

# Mark with description
virsh edit ubuntu-template
# Add: <description>Ubuntu 22.04 LTS base template</description>
```

### Clone from Template

```bash
#!/bin/bash
set -euo pipefail

TEMPLATE="ubuntu-template"
NEW_VM="web-server-01"
VM_DISK="/var/lib/libvirt/images/${NEW_VM}.qcow2"

# Clone the template
virt-clone \
    --original "$TEMPLATE" \
    --name "$NEW_VM" \
    --file "$VM_DISK"

# Start the clone
virsh start "$NEW_VM"

# Wait for boot and configure
sleep 10

# SSH into the new VM to customize
# virsh domifaddr "$NEW_VM" | grep ipv4  # Get IP
```

## Snapshot Management and Policies

### Structured Snapshot Strategy

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="db-server"

# Create snapshot before system updates
virsh snapshot-create-as "$VM_NAME" \
    --name "before-updates-$(date +%Y%m%d)" \
    --description "Pre-update snapshot on $(date)" \
    --atomic

# List all snapshots with dates
virsh snapshot-list "$VM_NAME" --tree

# Before major configuration change
virsh snapshot-create-as "$VM_NAME" \
    --name "before-postgres-upgrade" \
    --description "Database at stable version 13.0"

# Snapshot for quick rollback testing
virsh snapshot-create-as "$VM_NAME" \
    --name "current-stable" \
    --description "Known good state - regularly refreshed"
```

### Snapshot Retention Policy

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="web-server"
RETENTION_DAYS=7

# Delete snapshots older than retention period
virsh snapshot-list "$VM_NAME" --name | while read snap; do
    if [[ ! -z "$snap" ]]; then
        snap_date=$(virsh snapshot-info "$VM_NAME" "$snap" | grep "Creation time" | awk '{print $3}')
        snap_seconds=$(date -d "$snap_date" +%s 2>/dev/null || echo 0)
        current_seconds=$(date +%s)
        age_days=$(( ($current_seconds - $snap_seconds) / 86400 ))

        if [[ $age_days -gt $RETENTION_DAYS ]]; then
            echo "Deleting snapshot: $snap (Age: $age_days days)"
            virsh snapshot-delete "$VM_NAME" --snapshotname "$snap"
        fi
    fi
done

echo "Snapshot cleanup complete"
```

### Snapshot Monitoring

```bash
#!/bin/bash
set -euo pipefail

# Show snapshot chain and disk usage
for vm in $(virsh list --name); do
    echo "=== VM: $vm ==="
    virsh snapshot-list "$vm" 2>/dev/null || echo "  No snapshots"

    # Check snapshot file sizes
    virsh domblklist "$vm" | tail -n +3 | while read -r dev path; do
        if [[ -f "$path" ]]; then
            size=$(du -h "$path" | cut -f1)
            echo "  $dev: $size"
        fi
    done
done
```

## Backup Strategies for VMs

### Full VM Backup (Disk + Configuration)

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="${1:-web-server}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups/vms}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR/$VM_NAME"

# Backup VM configuration
virsh dumpxml "$VM_NAME" > "$BACKUP_DIR/$VM_NAME/config_${TIMESTAMP}.xml"

# Backup VM disk (using qemu-img for live backup without pausing)
VM_DISK=$(virsh domblklist "$VM_NAME" | tail -n +3 | awk '{print $2}' | head -1)

if [[ -n "$VM_DISK" ]]; then
    echo "Backing up disk: $VM_DISK"
    qemu-img convert -p -f qcow2 -O qcow2 \
        "$VM_DISK" \
        "$BACKUP_DIR/$VM_NAME/disk_${TIMESTAMP}.qcow2"
fi

# Calculate backup size
backup_size=$(du -sh "$BACKUP_DIR/$VM_NAME" | cut -f1)
echo "Backup complete: $backup_size"
```

### Incremental Backup with Snapshots

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="database-server"
BACKUP_DIR="/mnt/backups/vms"

# Create snapshot for backup
SNAP_NAME="backup-$(date +%s)"
virsh snapshot-create-as "$VM_NAME" --name "$SNAP_NAME" --atomic

# Backup the snapshot
VM_DISK=$(virsh domblklist "$VM_NAME" | tail -n +3 | awk '{print $2}' | head -1)

qemu-img convert -f qcow2 -O qcow2 \
    "$VM_DISK" \
    "$BACKUP_DIR/${VM_NAME}-${SNAP_NAME}.qcow2"

# Keep last 3 backups only
ls -tp "$BACKUP_DIR"/${VM_NAME}-* | tail -n +4 | xargs -d '\n' rm -f --

# Delete snapshot
virsh snapshot-delete "$VM_NAME" --snapshotname "$SNAP_NAME"
```

### Restore from Backup

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="web-server"
BACKUP_FILE="/mnt/backups/vms/web-server/disk_20240101_120000.qcow2"
CONFIG_FILE="/mnt/backups/vms/web-server/config_20240101_120000.xml"

# Stop VM if running
virsh shutdown "$VM_NAME" || true

# Replace disk
CURRENT_DISK=$(virsh domblklist "$VM_NAME" | tail -n +3 | awk '{print $2}' | head -1)
cp "$BACKUP_FILE" "$CURRENT_DISK"

# Start VM
virsh start "$VM_NAME"

echo "Restore complete"
```

## Monitoring VM Performance

### Real-Time Performance Monitoring

```bash
#!/bin/bash
set -euo pipefail

# Interactive monitoring (like top for VMs)
virt-top

# One-time snapshot of all VM stats
virsh list --all | tail -n +3 | while read id name state; do
    echo "=== VM: $name ==="
    virsh domstats "$name" --cpu --memory --block --net
done
```

### Detailed Performance Script

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="${1:-web-server}"
INTERVAL="${2:-5}"  # seconds

echo "Monitoring $VM_NAME (updating every ${INTERVAL}s)"
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== VM Performance: $VM_NAME ==="
    echo "Time: $(date)"
    echo ""

    # CPU info
    echo "--- CPU ---"
    virsh domstats "$VM_NAME" --cpu | grep -E "cpu|vcpu"

    # Memory info
    echo "--- Memory ---"
    virsh dominfo "$VM_NAME" | grep -i memory

    # Disk I/O
    echo "--- Disk I/O ---"
    virsh domblkstat "$VM_NAME" 2>/dev/null || echo "N/A"

    # Network I/O
    echo "--- Network ---"
    virsh domifstat "$VM_NAME" 2>/dev/null || echo "N/A"

    sleep "$INTERVAL"
done
```

## Automation with virsh and qm

### Automated Daily Backup Script

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/mnt/backups/vms"
RETENTION_DAYS=14
LOG_FILE="/var/log/vm-backups.log"

{
    echo "=== VM Backup Run: $(date) ==="

    # Create backup for each VM
    for vm in $(virsh list --name); do
        [[ -z "$vm" ]] && continue

        echo "Backing up: $vm"
        mkdir -p "$BACKUP_DIR/$vm"

        virsh dumpxml "$vm" > "$BACKUP_DIR/$vm/config.xml"

        VM_DISK=$(virsh domblklist "$vm" | tail -n +3 | awk '{print $2}' | head -1)
        if [[ -n "$VM_DISK" ]]; then
            qemu-img convert -f qcow2 -O qcow2 \
                "$VM_DISK" "$BACKUP_DIR/$vm/disk.qcow2"
        fi
    done

    # Clean old backups
    find "$BACKUP_DIR" -type f -mtime "+$RETENTION_DAYS" -delete

    echo "Backup complete"
} | tee -a "$LOG_FILE"

# Add to crontab:
# 0 2 * * * /usr/local/bin/backup-vms.sh
```

### VM Health Check Script

```bash
#!/bin/bash
set -euo pipefail

echo "=== VM Health Check ==="
echo "Time: $(date)"

issues=0

# Check all VMs
for vm in $(virsh list --name); do
    [[ -z "$vm" ]] && continue

    state=$(virsh dominfo "$vm" | grep "State" | awk '{print $3}')

    if [[ "$state" != "running" ]]; then
        echo "⚠️  WARNING: $vm is $state"
        ((issues++))
    fi

    # Check disk usage
    disk=$(virsh domblklist "$vm" | tail -n +3 | awk '{print $2}' | head -1)
    if [[ -n "$disk" ]]; then
        used=$(du -b "$disk" | cut -f1)
        max=$(qemu-img info "$disk" | grep "virtual size" | grep -oP '\d+' | head -1)
        percent=$((used * 100 / max))

        if [[ $percent -gt 90 ]]; then
            echo "⚠️  WARNING: $vm disk is ${percent}% full"
            ((issues++))
        fi
    fi
done

echo "Total issues found: $issues"
exit "$issues"
```

## Naming Conventions and Organization

### Structured Naming Scheme

```bash
#!/bin/bash
set -euo pipefail

# Naming format: [role]-[type]-[number]
# Examples:
# - web-server-01, web-server-02 (multiple web servers)
# - db-primary, db-secondary (database pair)
# - dev-ubuntu, dev-debian (development machines)
# - nas-backup-01 (backup/storage)
# - gateway-fw (firewall/gateway)
# - monitoring-prometheus (monitoring stack)

# Create VM with proper naming
create_vm() {
    local role="$1"    # web, db, dev, etc.
    local type="$2"    # server, primary, vm, etc.
    local number="$3"  # 01, 02, etc.

    local vm_name="${role}-${type}-${number}"
    echo "Creating: $vm_name"

    # virt-install with this name...
}

# Usage examples
create_vm "web" "server" "01"
create_vm "db" "primary" "01"
create_vm "dev" "ubuntu" "01"
```

### Organized Storage Structure

```bash
#!/bin/bash
set -euo pipefail

# Recommended directory layout
tree_structure=$(cat <<'EOF'
/var/lib/libvirt/
├── images/              # VM disks
│   ├── production/
│   │   ├── web-server-01.qcow2
│   │   └── db-primary.qcow2
│   ├── development/
│   │   └── dev-ubuntu-01.qcow2
│   └── templates/
│       ├── ubuntu-22.04.qcow2
│       └── debian-12.qcow2
├── isos/               # Installation media
├── snapshots/          # Snapshot storage
└── backups/            # Local backups
EOF
)

echo "$tree_structure"

# Create structure
mkdir -p /var/lib/libvirt/{images/{production,development,templates},isos,snapshots,backups}
```

## Documentation Practices

### VM Inventory Template

```bash
#!/bin/bash
set -euo pipefail

# Create inventory file
cat > /root/vm-inventory.md <<'EOF'
# VM Inventory - Last Updated: 2024-01-12

## Production VMs

### web-server-01
- **Purpose**: Primary web server
- **OS**: Ubuntu 22.04 LTS
- **Resources**: 4 vCPU, 4GB RAM, 40GB disk
- **Network**: IP 192.168.1.10, bridge br0
- **Services**: Nginx, PHP-FPM
- **Backups**: Daily, retained 14 days
- **Snapshots**: before-updates (Jan 10), stable (Jan 11)
- **Notes**: Monitor disk usage, frontend servers depend on this

### db-primary
- **Purpose**: Primary database server
- **OS**: Debian 12
- **Resources**: 8 vCPU, 16GB RAM, 200GB disk (fast SSD)
- **Network**: IP 192.168.1.11, bridge br0
- **Services**: PostgreSQL 15, pgBackRest
- **Backups**: Hourly WAL, daily full (retained 30 days)
- **Snapshots**: before-upgrade (Jan 10)
- **Notes**: Critical - monitor IO performance

## Development VMs

### dev-ubuntu-01
- **Purpose**: Development environment
- **OS**: Ubuntu 22.04 LTS
- **Resources**: 2 vCPU, 2GB RAM, 20GB disk
- **Network**: NAT (virbr0)
- **Services**: Docker, git, build tools
- **Backups**: Weekly
- **Notes**: Non-critical, can be recreated

EOF

cat /root/vm-inventory.md
```

### Configuration Documentation

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="web-server-01"
DOC_FILE="/root/docs/${VM_NAME}-config.md"

# Export and document VM configuration
mkdir -p /root/docs

cat > "$DOC_FILE" <<EOF
# Configuration: $VM_NAME

## Basic Info
- **Name**: $VM_NAME
- **Created**: $(date)
- **Template**: ubuntu-template

## Resources
$(virsh dominfo "$VM_NAME")

## Network
$(virsh domiflist "$VM_NAME")

## Storage
$(virsh domblklist "$VM_NAME")

## Current Snapshots
$(virsh snapshot-list "$VM_NAME" --name)

## Custom Notes
- Deployed for: Primary web server
- SSH key location: /root/.ssh/web-keys/
- Monitoring: Integrated with Prometheus
- Regular updates: Second Tuesday of month

EOF

echo "Documentation saved to: $DOC_FILE"
```

## Security Considerations

### VM Isolation and Network Security

```bash
#!/bin/bash
set -euo pipefail

# Create isolated network for sensitive VMs
sudo virsh net-define <<'EOF'
<network>
  <name>isolated-net</name>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.100' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-autostart isolated-net
virsh net-start isolated-net

# Connect sensitive VM to isolated network only
virsh attach-interface db-primary --type network --source isolated-net --persistent
```

### Access Control

```bash
#!/bin/bash
set -euo pipefail

# Restrict libvirt access via polkit
cat > /etc/polkit-1/rules.d/50-libvirt.rules <<'EOF'
polkit.addRule(function(action, subject) {
  if (action.id.indexOf("org.libvirt.") == 0 &&
      subject.isInGroup("libvirt")) {
    return polkit.Result.YES;
  }
});
EOF

# Add users to libvirt group (no root needed)
sudo usermod -aG libvirt username

# Verify permissions
id username
```

### Regular Security Updates

```bash
#!/bin/bash
set -euo pipefail

# Script to update all VMs
for vm in $(virsh list --name); do
    [[ -z "$vm" ]] && continue

    echo "Updating: $vm"

    # For Ubuntu/Debian based VMs
    virsh domifaddr "$vm" | grep ipv4 | awk '{print $4}' | cut -d/ -f1 | while read ip; do
        ssh -o StrictHostKeyChecking=no "user@$ip" \
            "sudo apt-get update && sudo apt-get upgrade -y"
    done
done
```

## Troubleshooting

### VM Fails to Start

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="problem-vm"

# Check detailed error
virsh start "$VM_NAME" 2>&1

# Validate XML
virsh define <(virsh dumpxml "$VM_NAME")

# Check system logs
sudo journalctl -u libvirtd -n 100 -e

# Verify disk and resources
virsh domblklist "$VM_NAME"
ls -l "$(virsh domblklist "$VM_NAME" | tail -1 | awk '{print $2}')"
```

### Disk Space Issues

```bash
#!/bin/bash
set -euo pipefail

# Check disk usage by VM
for vm in $(virsh list --name); do
    disk=$(virsh domblklist "$vm" | tail -n +3 | awk '{print $2}' | head -1)
    if [[ -n "$disk" ]]; then
        size=$(du -h "$disk" | cut -f1)
        echo "$vm: $size"
    fi
done | sort -hr

# Find and remove old backups
find /mnt/backups -type f -mtime +30 -delete
```

## Best Practices Summary

1. **Consistent Naming** - Use structured names reflecting purpose
2. **Resource Right-sizing** - Match resources to workload requirements
3. **Regular Backups** - Multiple backup strategies for critical VMs
4. **Documentation** - Keep inventory and configuration notes updated
5. **Snapshots** - Use before major changes, maintain retention policy
6. **Monitoring** - Regular health checks and performance monitoring
7. **Security** - Update hosts/VMs, use network isolation, control access
8. **Templates** - Base new VMs on well-configured templates
9. **Organization** - Logical directory structure for disks, ISOs, backups
10. **Testing** - Test restore procedures before you need them

## Additional Resources

- [libvirt Administration](https://libvirt.org/uri.html)
- [VM Backup Strategies](https://wiki.archlinux.org/title/QEMU#Snapshots)
- [Performance Tuning](https://www.kernel.org/doc/html/latest/virt/kvm/index.html)
- [Proxmox Administration](https://pve.proxmox.com/wiki/Backup_and_Restore)
- [KVM Best Practices](https://access.redhat.com/articles/6121681)

---

✅ **You now have comprehensive VM administration practices for stable, secure, well-documented homelab operations!**
