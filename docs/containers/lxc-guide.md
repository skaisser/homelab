# 📦 LXC System Containers Guide #lxc #containers #proxmox #system-containers

LXC (Linux Containers) provides system-level virtualization with OS-like containers, offering a middle ground between lightweight Docker containers and heavy virtual machines. Unlike Docker's application containers, LXC containers run full operating systems with init systems, making them ideal for running traditional services like Pi-hole, media servers, and network services. This guide covers LXC setup, management, and homelab-specific use cases.

## Table of Contents

- [LXC vs Docker: Understanding the Difference](#lxc-vs-docker-understanding-the-difference)
- [Installation and Setup](#installation-and-setup)
- [Creating LXC Containers](#creating-lxc-containers)
- [Template Management](#template-management)
- [Networking Configuration](#networking-configuration)
- [Storage: Bind Mounts and Volumes](#storage-bind-mounts-and-volumes)
- [Resource Limits](#resource-limits)
- [Privileged vs Unprivileged Containers](#privileged-vs-unprivileged-containers)
- [Container Security](#container-security)
- [Common Homelab Uses](#common-homelab-uses)
- [Container Migration](#container-migration)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## LXC vs Docker: Understanding the Difference

| Feature | LXC | Docker |
|---------|-----|--------|
| **Type** | System containers | Application containers |
| **Use Case** | Full OS in container | Single service |
| **Size** | 100MB-1GB | 10-100MB |
| **Init System** | Full (systemd) | None/minimal |
| **Services** | Multiple services | Single service |
| **Startup** | Seconds | Milliseconds |
| **Homelab Best For** | Services, DNS, NAS | Apps, databases |

**Use LXC when**:
- Running a full service stack (Pi-hole, media server, NAS)
- Need traditional sysadmin tools
- Managing multiple services in one container
- Want lightweight VMs

**Use Docker when**:
- Single containerized application
- Microservices architecture
- Need rapid scaling
- Working with orchestration (Kubernetes)

## Installation and Setup

### Install LXC on Debian/Ubuntu

```bash
#!/bin/bash
set -euo pipefail

# Update package lists
sudo apt-get update

# Install LXC package
sudo apt-get install -y \
    lxc \
    lxc-templates \
    lxd \
    bridge-utils \
    debootstrap

# Start LXD daemon
sudo systemctl start lxd
sudo systemctl enable lxd

# Initialize LXD (defaults recommended for homelab)
sudo lxd init --auto

# Add user to lxd group (optional, requires logout/login)
sudo usermod -aG lxd "$USER"

# Verify installation
lxc version
lxc list
```

### Using Proxmox with LXC (Recommended for Homelabs)

```bash
#!/bin/bash
set -euo pipefault

# Proxmox integrates LXC management with Web UI
# Access Proxmox Web Interface: https://<ip>:8006

# Via command line on Proxmox host:
# Create container (example)
pct create <vmid> local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst \
    --hostname mycontainer \
    --cores 2 \
    --memory 1024 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp

# Start container
pct start <vmid>

# Stop container
pct stop <vmid>
```

## Creating LXC Containers

### Create Container with LXC

```bash
#!/bin/bash
set -euo pipefail

CONTAINER_NAME="ubuntu-service"
DISTRO="ubuntu"
RELEASE="jammy"  # 22.04
ARCH="amd64"

# Create container from template
sudo lxc-create -n "$CONTAINER_NAME" -t download -- \
    --dist "$DISTRO" \
    --release "$RELEASE" \
    --arch "$ARCH"

# Start container
sudo lxc-start -n "$CONTAINER_NAME"

# Verify it's running
sudo lxc-ls -f

# Get container IP
sudo lxc-attach -n "$CONTAINER_NAME" -- ip addr show

# Access container console
sudo lxc-console -n "$CONTAINER_NAME"
# Or shell access
sudo lxc-attach -n "$CONTAINER_NAME" -- /bin/bash
```

### Create Container with LXD (Modern Approach)

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="ubuntu-service"

# List available images
lxc image list images: | grep ubuntu

# Create container
lxc launch images:ubuntu/22.04 "$CONTAINER_NAME"

# Wait for container to initialize
sleep 3

# Check status
lxc list "$CONTAINER_NAME"

# Get IP address
lxc list "$CONTAINER_NAME" --format=json | grep -oP '"ipv4":\s*"\K[^"]*'

# Access shell
lxc exec "$CONTAINER_NAME" -- bash

# Stop and start
lxc stop "$CONTAINER_NAME"
lxc start "$CONTAINER_NAME"
```

### Container Initialization Script

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="${1:-ubuntu-service}"

# Create container
lxc launch images:ubuntu/22.04 "$CONTAINER_NAME"

# Wait for network
sleep 5

# Run initialization commands
lxc exec "$CONTAINER_NAME" -- apt-get update
lxc exec "$CONTAINER_NAME" -- apt-get upgrade -y
lxc exec "$CONTAINER_NAME" -- apt-get install -y \
    curl \
    wget \
    htop \
    net-tools \
    git

# Set timezone
lxc exec "$CONTAINER_NAME" -- timedatectl set-timezone UTC

# Enable auto-start (on Proxmox)
# pct set <vmid> --onboot 1

echo "Container $CONTAINER_NAME initialized"
```

## Template Management

### Create Container Template

```bash
#!/bin/bash
set -euo pipefault

# Create and configure a container as template
lxc launch images:ubuntu/22.04 template-ubuntu

# Wait for initialization
sleep 5

# Configure template
lxc exec template-ubuntu -- apt-get update
lxc exec template-ubuntu -- apt-get upgrade -y
lxc exec template-ubuntu -- apt-get install -y \
    openssh-server \
    curl \
    wget \
    ca-certificates

# Publish as image (LXD)
lxc publish template-ubuntu --alias ubuntu-base

# List published images
lxc image list

# Create containers from custom image
lxc launch ubuntu-base container-1
lxc launch ubuntu-base container-2
```

### Proxmox Template Management

```bash
#!/bin/bash
set -euo pipefault

# On Proxmox, convert container to template via Web UI:
# 1. Right-click container > Convert to template
# Or via command line:
# pct set <vmid> --template 1

# Clone from template
pct clone <template-vmid> <new-vmid> --hostname new-container

# Remove template status
# pct set <vmid> --template 0
```

## Networking Configuration

### Bridge Networking (Shared Network)

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="ubuntu-service"

# Configure container for bridge mode (LXD)
lxc network attach-profile default eth0 "$CONTAINER_NAME"

# Or manually set network device
lxc config device add "$CONTAINER_NAME" eth0 nic \
    nictype=bridged \
    parent=br0 \
    name=eth0

# Inside container, configure DHCP or static IP
lxc exec "$CONTAINER_NAME" -- cat > /etc/netplan/01-netcfg.yaml <<'EOF'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF

lxc exec "$CONTAINER_NAME" -- netplan apply

# Get assigned IP
lxc exec "$CONTAINER_NAME" -- ip addr show eth0
```

### Static IP Configuration

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="ubuntu-service"
CONTAINER_IP="192.168.1.100"
GATEWAY="192.168.1.1"
DNS="8.8.8.8 1.1.1.1"

# Set network device
lxc config device add "$CONTAINER_NAME" eth0 nic \
    nictype=bridged \
    parent=br0 \
    ipv4.address="$CONTAINER_IP/24"

# Or configure inside container
lxc exec "$CONTAINER_NAME" -- cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - $CONTAINER_IP/24
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF

lxc exec "$CONTAINER_NAME" -- netplan apply
```

### Isolated Network (Private)

```bash
#!/bin/bash
set -euo pipefault

# Create private network
lxc network create private-net ipv4.address=10.0.1.1 ipv4.nat=true

# Attach container to private network
lxc config device add container-name eth1 nic \
    nictype=bridged \
    parent=private-net

# Container can communicate with host and other containers, but is isolated from LAN
```

### Port Forwarding

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="webserver"
CONTAINER_IP="192.168.1.100"
HOST_PORT=8080
CONTAINER_PORT=80

# Forward host port to container
sudo iptables -t nat -A PREROUTING -p tcp \
    --dport "$HOST_PORT" \
    -j DNAT --to-destination "$CONTAINER_IP:$CONTAINER_PORT"

# Make persistent with iptables-persistent
sudo apt-get install -y iptables-persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Or using LXC proxy device (LXD)
lxc config device add "$CONTAINER_NAME" http-proxy proxy \
    listen=tcp:0.0.0.0:8080 \
    connect=tcp:127.0.0.1:80
```

## Storage: Bind Mounts and Volumes

### Bind Mounts (Host Directory Access)

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="storage-service"
HOST_PATH="/mnt/homelab/media"
CONTAINER_PATH="/media"

# Create directory on host
sudo mkdir -p "$HOST_PATH"

# Add bind mount to container
lxc config device add "$CONTAINER_NAME" media disk \
    source="$HOST_PATH" \
    path="$CONTAINER_PATH"

# Verify inside container
lxc exec "$CONTAINER_NAME" -- mount | grep "$CONTAINER_PATH"

# Test write access
lxc exec "$CONTAINER_NAME" -- touch "$CONTAINER_PATH/test.txt"
ls -la "$HOST_PATH"
```

### LXD Storage Volumes

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="database-service"
VOLUME_NAME="db-data"
CONTAINER_PATH="/var/lib/postgresql"

# Create storage pool (if not exists)
lxc storage create local dir source=/var/lib/lxd/storage-local

# Create volume
lxc storage volume create local "$VOLUME_NAME"

# Attach volume to container
lxc config device add "$CONTAINER_NAME" db-volume disk \
    pool=local \
    source="$VOLUME_NAME" \
    path="$CONTAINER_PATH"

# List volumes
lxc storage volume list local
```

### Backup Container Storage

```bash
#!/bin/bash
set -euo pipefaft

CONTAINER_NAME="backup-target"
BACKUP_DIR="/mnt/backups"

# Full container backup (LXD)
lxc export "$CONTAINER_NAME" "$BACKUP_DIR/${CONTAINER_NAME}.tar.gz"

# Restore from backup
lxc import "$BACKUP_DIR/${CONTAINER_NAME}.tar.gz" restored-container

# Backup individual volume
lxc storage volume export local volume-name \
    "$BACKUP_DIR/volume-backup.tar.gz"
```

## Resource Limits

### CPU and Memory Limits

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="limited-container"

# Set CPU cores (2 cores)
lxc config set "$CONTAINER_NAME" limits.cpu=2

# Set memory limit (1GB)
lxc config set "$CONTAINER_NAME" limits.memory=1GB

# Set memory swap (optional)
lxc config set "$CONTAINER_NAME" limits.memory.swap=true
lxc config set "$CONTAINER_NAME" limits.memory.swap.priority=-10

# View current limits
lxc config show "$CONTAINER_NAME" | grep limits

# Apply changes (may require restart)
lxc restart "$CONTAINER_NAME"
```

### Disk I/O Limits

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="io-limited"

# Limit disk read/write throughput (MB/s)
lxc config device set "$CONTAINER_NAME" root limits.read=100MB
lxc config device set "$CONTAINER_NAME" root limits.write=50MB

# Limit disk I/O operations (IOPS)
lxc config device set "$CONTAINER_NAME" root limits.read-iops=1000
lxc config device set "$CONTAINER_NAME" root limits.write-iops=500

# Remove limit
lxc config device unset "$CONTAINER_NAME" root limits.read
```

### Network Rate Limiting

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="network-limited"

# Limit network bandwidth (100Mbps)
lxc config device set "$CONTAINER_NAME" eth0 limits.ingress=100Mbit
lxc config device set "$CONTAINER_NAME" eth0 limits.egress=100Mbit

# Or in bytes/s
lxc config device set "$CONTAINER_NAME" eth0 limits.ingress=12500000B
```

## Privileged vs Unprivileged Containers

### Unprivileged Containers (Secure, Recommended)

```bash
#!/bin/bash
set -euo pipefault

# Default is unprivileged (UID mapping)
# User 0 (root) inside container = non-root user on host

# Create unprivileged container
lxc launch images:ubuntu/22.04 unprivileged-container

# Verify unprivileged
lxc config show unprivileged-container | grep security
```

### Privileged Containers (Less Secure, Sometimes Necessary)

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="privileged-container"

# Set privileged mode
lxc config set "$CONTAINER_NAME" security.privileged=true

# This allows raw device access, mount operations, etc.
# Only use if necessary for specific services

# Restart container
lxc restart "$CONTAINER_NAME"
```

## Container Security

### Basic Security Hardening

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="secure-container"

# Disable raw socket access
lxc config set "$CONTAINER_NAME" security.raw.sockets=false

# Restrict syscalls
lxc config set "$CONTAINER_NAME" security.syscalls.deny=keyctl,ptrace

# Set read-only root filesystem (for stateless apps)
lxc config set "$CONTAINER_NAME" security.protection.shift=true

# Use seccomp profile
lxc config set "$CONTAINER_NAME" security.seccomp=true
```

### Inside Container Security

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="ubuntu-service"

# Update system
lxc exec "$CONTAINER_NAME" -- apt-get update
lxc exec "$CONTAINER_NAME" -- apt-get upgrade -y

# Disable unnecessary services
lxc exec "$CONTAINER_NAME" -- systemctl disable avahi-daemon

# Configure firewall
lxc exec "$CONTAINER_NAME" -- apt-get install -y ufw
lxc exec "$CONTAINER_NAME" -- ufw enable
lxc exec "$CONTAINER_NAME" -- ufw default deny incoming
lxc exec "$CONTAINER_NAME" -- ufw allow 22/tcp

# SSH hardening
lxc exec "$CONTAINER_NAME" -- sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
lxc exec "$CONTAINER_NAME" -- sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH
lxc exec "$CONTAINER_NAME" -- systemctl restart ssh
```

## Common Homelab Uses

### Pi-hole DNS Container

```bash
#!/bin/bash
set -euo pipefault

# Create container
lxc launch images:ubuntu/22.04 pihole

# Assign static IP
lxc config device add pihole eth0 nic \
    nictype=bridged \
    parent=br0 \
    ipv4.address=192.168.1.53/24

# Install Pi-hole
lxc exec pihole -- bash -c 'curl -sSL https://install.pi-hole.net | bash'

# Get admin password
lxc exec pihole -- grep "Admin password" /etc/pihole/setupVars.conf

# Access at http://<container-ip>/admin

# Point home devices' DNS to container IP
```

### Jellyfin Media Server

```bash
#!/bin/bash
set -euo pipefact

# Create container
lxc launch images:ubuntu/22.04 jellyfin

# Assign sufficient resources
lxc config set jellyfin limits.memory=4GB
lxc config set jellyfin limits.cpu=4

# Mount media library
lxc config device add jellyfin media disk \
    source=/mnt/media \
    path=/media

# Install Jellyfin
lxc exec jellyfin -- apt-get update
lxc exec jellyfin -- apt-get install -y jellyfin

# Start service
lxc exec jellyfin -- systemctl start jellyfin
lxc exec jellyfin -- systemctl enable jellyfin

# Access at http://<container-ip>:8096
```

### Home Automation Stack (HA)

```bash
#!/bin/bash
set -euo pipefault

# Create Home Assistant container
lxc launch images:debian/12 homeassistant

# Install Python and Home Assistant
lxc exec homeassistant -- apt-get install -y python3 python3-venv

# Create HA user and directory
lxc exec homeassistant -- useradd -m -d /home/homeassistant homeassistant
lxc exec homeassistant -- mkdir -p /home/homeassistant/.homeassistant

# Install Home Assistant
lxc exec homeassistant -- sudo -u homeassistant python3 -m venv /home/homeassistant/venv
lxc exec homeassistant -- sudo -u homeassistant bash -c \
    'source /home/homeassistant/venv/bin/activate && pip install homeassistant'

# Create systemd service
lxc exec homeassistant -- cat > /etc/systemd/system/homeassistant.service <<'EOF'
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=homeassistant
ExecStart=/home/homeassistant/venv/bin/hass -c /home/homeassistant/.homeassistant
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start service
lxc exec homeassistant -- systemctl daemon-reload
lxc exec homeassistant -- systemctl enable homeassistant
lxc exec homeassistant -- systemctl start homeassistant

# Access at http://<container-ip>:8123
```

### NAS Services Container

```bash
#!/bin/bash
set -euo pipefact

# Create NAS container
lxc launch images:ubuntu/22.04 nas

# Mount storage volumes
lxc config device add nas storage disk \
    source=/mnt/storage \
    path=/mnt/storage

# Install NAS services
lxc exec nas -- apt-get install -y \
    samba \
    nfs-kernel-server \
    avahi-daemon

# Configure Samba share
lxc exec nas -- cat >> /etc/samba/smb.conf <<'EOF'
[media]
    path = /mnt/storage/media
    browseable = yes
    writable = yes
    public = yes
EOF

# Restart Samba
lxc exec nas -- systemctl restart smbd

# NFS export
lxc exec nas -- echo '/mnt/storage *(rw,sync,no_subtree_check)' >> /etc/exports
lxc exec nas -- exportfs -a
```

## Container Migration

### Migrate Container to Another Host

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="mycontainer"
SOURCE_HOST="host1"
DEST_HOST="host2"

# On source host, export container
lxc export "$CONTAINER_NAME" /tmp/"$CONTAINER_NAME".tar.gz

# Copy to destination
scp /tmp/"$CONTAINER_NAME".tar.gz user@"$DEST_HOST":/tmp/

# On destination host, import container
ssh user@"$DEST_HOST" "lxc import /tmp/${CONTAINER_NAME}.tar.gz ${CONTAINER_NAME}"

# Start imported container
ssh user@"$DEST_HOST" "lxc start $CONTAINER_NAME"

# Delete from source (after verification)
lxc delete "$CONTAINER_NAME"
```

## Troubleshooting

### Container Won't Start

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="broken-container"

# Check container status
lxc info "$CONTAINER_NAME"

# View logs
lxc console "$CONTAINER_NAME" --show-log

# Try starting with debug
lxc start "$CONTAINER_NAME" -vvv 2>&1 | tee /tmp/lxc-debug.log

# Reset container
lxc restart "$CONTAINER_NAME" --force

# If still broken, export and reimport
lxc export "$CONTAINER_NAME" /tmp/backup.tar.gz
lxc delete "$CONTAINER_NAME"
lxc import /tmp/backup.tar.gz "$CONTAINER_NAME"
```

### Network Issues

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="network-issue"

# Check container network
lxc exec "$CONTAINER_NAME" -- ip addr show
lxc exec "$CONTAINER_NAME" -- ip route show

# Check host bridge
sudo brctl show

# Ping container from host
lxc exec "$CONTAINER_NAME" -- ping 8.8.8.8

# Check DNS
lxc exec "$CONTAINER_NAME" -- cat /etc/resolv.conf
lxc exec "$CONTAINER_NAME" -- nslookup google.com

# Reconfigure network
lxc config device remove "$CONTAINER_NAME" eth0
lxc config device add "$CONTAINER_NAME" eth0 nic \
    nictype=bridged \
    parent=br0 \
    ipv4.address=dhcp
```

### Storage Mount Issues

```bash
#!/bin/bash
set -euo pipefault

CONTAINER_NAME="storage-issue"

# Check mounted devices
lxc exec "$CONTAINER_NAME" -- mount | grep /media

# Check permissions
lxc exec "$CONTAINER_NAME" -- ls -la /media

# Verify host path exists
ls -la /mnt/homelab/media

# Recreate mount
lxc config device remove "$CONTAINER_NAME" media
lxc config device add "$CONTAINER_NAME" media disk \
    source=/mnt/homelab/media \
    path=/media
```

## Best Practices

1. **Use Templates** - Create base templates to speed up container creation
2. **Resource Limits** - Set realistic CPU/memory limits to prevent resource exhaustion
3. **Regular Backups** - Export containers monthly or before major changes
4. **Security** - Run unprivileged containers when possible
5. **Network Planning** - Use multiple networks for isolation if needed
6. **Storage Organization** - Keep bind mounts and volumes organized with clear naming
7. **Monitoring** - Use `lxc list` and `lxc monitor` to watch container status
8. **Documentation** - Document purpose, config, and startup instructions for each container
9. **Updates** - Regularly update container OS and services
10. **Snapshots** - Create snapshots before major updates (LXD)

## Additional Resources

- [LXC Documentation](https://linuxcontainers.org/)
- [LXD Documentation](https://linuxcontainers.org/lxd/introduction/)
- [Proxmox LXC Guide](https://pve.proxmox.com/wiki/Linux_Container)
- [LXC vs Docker](https://linuxcontainers.org/lxc/introduction/)
- [LXC Security](https://linuxcontainers.org/lxc/security/)

---

✅ **You now have comprehensive LXC container knowledge for running system services in your homelab!**
