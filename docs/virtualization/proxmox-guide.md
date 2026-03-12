# 🖥 Proxmox VE Administration Guide #proxmox #virtualization #containers #storage #networking

Comprehensive guide for managing Proxmox Virtual Environment (PVE), including VM management, storage, networking, and cluster operations.

## 🔗 Quick Access Links
### Proxmox Helper Scripts
- [Community Scripts Collection](https://community-scripts.github.io/ProxmoxVE/)
- [Post-Install Script](https://github.com/community-scripts/ProxmoxVE/blob/main/tools/pve/post-pve-install.sh)

## 📋 Table of Contents
- [Initial Setup](#-initial-setup)
- [VM Management](#-vm-management)
- [Container Management](#-container-management)
- [Storage Management](#-storage-management)
- [Network Configuration](#-network-configuration)
- [Cluster Operations](#-cluster-operations)
- [Backup & Restore](#-backup--restore)
- [Performance Tuning](#-performance-tuning)

## 🔧 Initial Setup

### Storage Configuration
1. **Reclaim Local LVM Space**
   - Navigate to **Datacenter > Storage**
   - Delete the Local LVM storage
   - Access server shell through **Datacenter > your_proxmox_server > Shell**
   - Run these commands:
   ```bash
   # Remove old LVM data volume
   lvremove /dev/pve/data

   # Extend root volume to use all space
   lvresize -l +100%FREE /dev/pve/root

   # Resize filesystem to use new space
   resize2fs /dev/pve/root
   ```

### Network Bridge Setup
1. **Create br0 Bridge**
   - Navigate to **Datacenter > your_proxmox_server > Network**
   - Click **Create > Linux Bridge**
   - Configure settings:
     - Name: `br0`
     - Bridge ports: Select best network interface (lowest latency)
     - VLAN aware: Enable if using VLANs
   - Click **Add**
   - Click **Apply Configuration**

2. **Verify Bridge Status**
   ```bash
   # Check bridge status
   brctl show br0

   # Verify network connectivity
   ping -c 4 gateway_ip
   ```

### Post-Installation Tasks
To use the Proxmox VE Post Install script, run the command below **only** in the Proxmox VE Shell. This script is intended for managing or enhancing the host system directly.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```

1. **Security Setup**
   ```bash
   # Set root password
   passwd

   # Configure SSH (optional)
   nano /etc/ssh/sshd_config
   ```

## 💻 VM Management

### Virtual Machine Operations
```bash
# List all VMs
qm list

# Start/Stop VM
qm start 100
qm stop 100

# Shutdown/Reset VM
qm shutdown 100
qm reset 100

# Create VM snapshot
qm snapshot 100 snap1 "Initial snapshot"

# List snapshots
qm listsnapshot 100

# Restore snapshot
qm rollback 100 snap1
```

### VM Creation and Cloning
```bash
# Create VM from ISO
qm create 101 \
    --name "ubuntu-vm" \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --ide2 local:iso/ubuntu-20.04-server-amd64.iso,media=cdrom

# Clone VM
qm clone 100 101 --name "clone-vm"

# Convert VM to template
qm template 100
```

## 💾 Container Management

### LXC Operations
```bash
# List containers
pct list

# Create container
pct create 200 local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz \
    --hostname ubuntu-ct \
    --memory 512 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp

# Start/Stop container
pct start 200
pct stop 200

# Enter container shell
pct enter 200
```

## 📂 Storage Management

### Storage Operations
```bash
# List storage
pvesm status

# Add storage
pvesm add nfs storage-name \
    --path /mnt/storage \
    --server 192.168.1.100 \
    --export /export/data

# Scan storage content
pvesm scan storage-name
```

### Disk Management
```bash
# List disks
lsblk

# Create ZFS pool
zpool create tank mirror sda sdb

# Add storage to Proxmox
pvesm add zfspool tank-storage \
    --pool tank \
    --content images,rootdir
```

## 🔸 Network Configuration

### Network Operations
```bash
# Show network config
cat /etc/network/interfaces

# Create bridge
cat >> /etc/network/interfaces << EOF
auto vmbr1
iface vmbr1 inet static
    address 192.168.1.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
EOF

# Apply network changes
ifreload -a
```

### Firewall Management
```bash
# List firewall rules
pve-firewall status

# Add rule
pve-firewall create_rule \
    --action ACCEPT \
    --proto tcp \
    --dport 80
```

## 🔍 Cluster Operations

### Cluster Management
```bash
# Create cluster
pvecm create mycluster

# Add node
pvecm add node2.domain.com

# Show cluster status
pvecm status

# List nodes
pvecm nodes
```

## 📋 Backup & Restore

### Backup Operations
```bash
# Create backup
vzbackup 100 /mnt/backup/

# Schedule backup
cat > /etc/cron.d/pve-backup << EOF
0 2 * * * root vzdump 100 --compress zstd --mode snapshot
EOF

# Restore from backup
vzrestore /mnt/backup/vzdump-qemu-100.vma.zst 100
```

## 🏑 Performance Tuning

### System Monitoring
```bash
# CPU info
lscpu

# Memory usage
free -h

# I/O stats
iostat -xz 1

# Network stats
sar -n DEV 1
```

### Resource Management
```bash
# Set CPU limits
qm set 100 --cpulimit 50

# Set memory limits
qm set 100 --memory 4096

# Enable hugepages
echo "vm.nr_hugepages = 1024" >> /etc/sysctl.conf
sysctl -p
```

## 🔧 Troubleshooting

### Common Issues

1. **VM Won't Start**
   ```bash
   # Check logs
tail -f /var/log/pve/qemu-server/100.log

   # Check resources
pvesh get /nodes/localhost/status
   ```

2. **Network Issues**
   ```bash
   # Check bridge status
brctl show

   # Test connectivity
ping -c 4 VM_IP
   ```

3. **Storage Problems**
   ```bash
   # Check storage status
pvesm status

   # Verify ZFS pool
zpool status
   ```

### Best Practices

#### Performance
- Use virtio drivers for VMs
- Enable NUMA for large VMs
- Use SSDs for VM storage
- Monitor resource usage

#### Security
- Keep Proxmox updated
- Use secure passwords
- Enable firewall
- Regular backups

#### Maintenance
- Regular updates
- Monitor logs
- Test backups
- Document changes

> 💡 **Pro Tips**:
> - Use templates for quick deployment
> - Implement resource limits
> - Monitor performance metrics
> - Keep snapshots current

## 📚 Additional Resources

### Official Documentation
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox Wiki](https://pve.proxmox.com/wiki/Main_Page)
- [Community Scripts](https://community-scripts.github.io/ProxmoxVE/)

### Community Support
- [Proxmox Forums](https://forum.proxmox.com/)
- [Reddit r/Proxmox](https://www.reddit.com/r/Proxmox/)

---

✅ Use this guide as a reference for managing your Proxmox VE environment. Always test commands in a safe environment first.
