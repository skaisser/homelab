# 💿 OS Installation & Initial Setup #setup #installation #linux #debian #ubuntu

Step-by-step guide to installing and configuring a server operating system for your homelab.

## Table of Contents
1. [Choosing an OS](#choosing-an-os)
2. [Creating Bootable Media](#creating-bootable-media)
3. [Installation Process](#installation-process)
4. [Post-Install Essentials](#post-install-essentials)
5. [Basic Hardening](#basic-hardening)
6. [First Boot](#first-boot)
7. [Network Configuration](#network-configuration)
8. [System Updates](#system-updates)
9. [Verification Steps](#verification-steps)
10. [Common Issues](#common-issues)

## Choosing an OS

### Debian vs Ubuntu Server
```
DEBIAN
Pros:
- Extremely stable, conservative updates
- Smaller footprint
- Perfect for long-term deployments
- Very predictable

Cons:
- Older software versions
- Less community support for bleeding edge

Best for:
- Production services
- Long-term stability priority
- Experienced Linux users

Versions: Debian 12 (Bookworm - stable)

UBUNTU SERVER
Pros:
- More frequent updates (6 months)
- Newer software
- Larger community support
- Better for learning

Cons:
- Faster change rate
- Shorter support windows

Best for:
- Learning
- Trying new software
- Faster development cycle

Versions: Ubuntu 24.04 LTS (recommended)
Support: 5 years (LTS)
```

### Other Options
```
PROXMOX VE
- Hypervisor OS (Debian-based)
- Full virtualization stack included
- Web GUI management
- Good if planning VMs from start

ROCKYLINUX / ALMALINUX
- RHEL alternatives
- RPM-based (different package manager)
- Good for learning different distros
- Enterprise focus

RECOMMENDATION: Ubuntu Server 24.04 LTS for beginners
```

## Creating Bootable Media

### Method 1: Ventoy (Recommended)
```bash
# Download Ventoy from: https://www.ventoy.net/
# Supports multiple ISO files at once

# On Linux:
# 1. Download Ventoy binary
# 2. Extract to USB drive
ventoy-1.0.96/Ventoy2Disk.sh -i /dev/sdb

# 3. Copy ISO files to USB
cp ubuntu-24.04-live-server-amd64.iso /mnt/ventoy/

# 4. Boot from USB, select ISO from menu

# Advantages:
- No flashing needed
- Multiple ISOs on one USB
- Easy to update
```

### Method 2: Balena Etcher (GUI)
```bash
# Download from: https://www.balena.io/etcher/
# Works on Windows, Mac, Linux

# Steps:
# 1. Open Balena Etcher
# 2. Select image: ubuntu-24.04-live-server-amd64.iso
# 3. Select target: /dev/sdb (USB drive)
# 4. Click Flash
# 5. Wait for completion

# Linux command line alternative:
sudo apt-get install balena-etcher-electron
# Then use GUI
```

### Method 3: dd Command (Advanced)
```bash
# Direct disk write (advanced users)
# WARNING: dd can destroy data if wrong device!

# Identify USB drive
lsblk
# Find your USB (e.g., /dev/sdb)

# Unmount if mounted
sudo umount /dev/sdb*

# Write ISO
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdb bs=4M status=progress
sudo sync

# Eject safely
sudo eject /dev/sdb
```

### Downloading ISOs
```bash
# Ubuntu Server (recommended for homelab)
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Debian (more conservative)
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso

# Verify ISO integrity
sha256sum ubuntu-24.04-live-server-amd64.iso
# Compare with official hash from website
```

## Installation Process

### Pre-Installation Checklist
```bash
# Required:
✓ USB drive with bootable ISO (8GB+ for most distros)
✓ Computer with BIOS/UEFI access
✓ Keyboard and monitor
✓ Disk large enough for OS (50GB+ recommended)

# Recommended:
✓ Ethernet connection (better than WiFi for install)
✓ Second monitor (useful for documentation)
✓ Knowledge of machine specifications
```

### Boot Process
```
1. Insert USB drive
2. Power on computer
3. Enter boot menu (varies by manufacturer):
   - Dell: F12 during boot
   - HP: F9 during boot
   - Lenovo: F12 during boot
   - ASUS: F8 or Delete during boot
4. Select USB drive from menu
5. Press Enter to boot
```

### Ubuntu Server Installation Walkthrough
```
WELCOME SCREEN
→ Choose language: English
→ Continue

KEYBOARD CONFIGURATION
→ Select layout: English (US)
→ Continue

NETWORK CONFIGURATION
→ Leave DHCP on for automatic
→ Can configure static IP later
→ Continue

PROXY CONFIGURATION
→ Leave blank (no proxy)
→ Continue

MIRROR SELECTION
→ Use default Ubuntu archive
→ Continue

STORAGE CONFIGURATION (IMPORTANT)
→ Careful selection here!
→ For new install: Use entire disk
→ For VM: Select new partition
→ Review: Shows what will be deleted
→ Confirm: "Done"

FILESYSTEM SETUP
→ Choose default partition layout
→ ext4 filesystem recommended
→ Continue

PROFILE SETUP
→ Your name: [Enter full name]
→ Server name: homelab-1 (keep simple, lowercase)
→ Username: [Preferred username]
→ Password: [Strong password - write down!]
→ Confirm password
→ Continue

SSH SETUP
→ Install OpenSSH: [X] Check this box
→ Import SSH keys: Skip (or import from GitHub)
→ Continue

FEATURED SNAPS
→ Skip unless you need specific tools
→ Continue

FINAL INSTALLATION
→ System installs (5-10 minutes)
→ After completion: "Reboot Now"
→ Remove USB drive when asked
```

### Debian Installation (Similar)
```
Install process very similar to Ubuntu

Key differences:
- Asks for root password (set this carefully)
- May ask about software selection
- No snap packages (deselect if offered)
- Desktop environment: Deselect all
- SSH server: Select to install

After first questions, proceeds similarly to Ubuntu
```

## Post-Install Essentials

### First Boot Login
```bash
# System boots and shows login prompt
# At "login:" prompt, enter username
# At "Password:" prompt, enter password (won't show as you type)

# You're now at command prompt!
$ whoami          # Confirm user
$ hostname        # Confirm server name
$ ip addr show    # Check IP address
```

### Update Package Manager
```bash
# Critical first step - update all packages
sudo apt-get update        # Refresh package list (5-10 seconds)
sudo apt-get upgrade       # Upgrade all installed packages (5-30 minutes)

# Optional, cleaner version:
sudo apt update && sudo apt upgrade -y

# For major version upgrades
sudo apt full-upgrade      # Install new versions (rarely needed)
sudo apt autoremove        # Remove unused packages
```

### Create Sudo User (If Using Root)
```bash
# If you installed as root only:
sudo useradd -m -s /bin/bash myusername
sudo usermod -aG sudo myusername
sudo passwd myusername    # Set password

# Now logout and login as new user
exit
# Login as myusername
```

### Set Hostname
```bash
# View current hostname
hostnamectl

# Set new hostname
sudo hostnamectl set-hostname homelab-1

# Verify
hostnamectl

# Also update /etc/hosts for consistency
sudo nano /etc/hosts
# Change:
# 127.0.0.1 localhost
# to:
# 127.0.0.1 localhost homelab-1
```

### Configure Timezone
```bash
# View current timezone
timedatectl

# List available timezones
timedatectl list-timezones | grep America  # Filter by region

# Set timezone
sudo timedatectl set-timezone America/New_York

# Verify
timedatectl
```

### Install Essential Tools
```bash
# Useful utilities for any homelab
sudo apt-get install -y \
  curl \
  wget \
  git \
  htop \
  net-tools \
  nmap \
  telnet \
  vim \
  nano \
  tmux \
  btop \
  dnsutils \
  whois \
  jq

# Verify installation
curl --version
git --version
htop --version
```

## Basic Hardening

### SSH Key Authentication
```bash
# On your LOCAL machine (not the server):
ssh-keygen -t ed25519 -C "homelab@example.com" -f ~/.ssh/homelab
# This creates two files:
# ~/.ssh/homelab (private key - keep secret!)
# ~/.ssh/homelab.pub (public key - share with server)

# Copy public key to server (from local machine):
cat ~/.ssh/homelab.pub | ssh username@homelab-1 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
# Or manually:
# 1. Open ~/.ssh/homelab.pub
# 2. SSH to server
# 3. Run: mkdir -p ~/.ssh
# 4. Create file ~/.ssh/authorized_keys with content
# 5. chmod 600 ~/.ssh/authorized_keys

# Test key login from local machine:
ssh -i ~/.ssh/homelab username@homelab-1
```

### Disable Password SSH Login
```bash
# Edit SSH config on server:
sudo nano /etc/ssh/sshd_config

# Find and change these lines:
# PermitRootLogin no           (already should be this)
# PasswordAuthentication no    (change to: no)
# PubkeyAuthentication yes     (should already be yes)

# Save file (Ctrl+O, Enter, Ctrl+X)

# Restart SSH
sudo systemctl restart ssh

# Verify from another terminal before disconnecting!
ssh -i ~/.ssh/homelab username@homelab-1
```

### Change SSH Port (Optional)
```bash
# More security through obscurity
sudo nano /etc/ssh/sshd_config

# Find: #Port 22
# Change to: Port 2222

sudo systemctl restart ssh

# Connect using new port:
ssh -i ~/.ssh/homelab -p 2222 username@homelab-1

# Remember port in ~/.ssh/config:
Host homelab-1
    HostName homelab-1.local
    User username
    Port 2222
    IdentityFile ~/.ssh/homelab
```

### Firewall Setup (UFW)
```bash
# Enable firewall
sudo ufw enable

# Allow SSH (critical!)
sudo ufw allow 22/tcp     # Or custom port:
sudo ufw allow 2222/tcp   # If changed port above

# Check status
sudo ufw status verbose

# Allow other common ports
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS

# Deny specific IP
sudo ufw deny from 192.168.1.100

# View all rules
sudo ufw show added
```

### Fail2ban (Optional but Recommended)
```bash
# Install
sudo apt-get install fail2ban

# Enable
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo systemctl status fail2ban
sudo fail2ban-client status

# View blocked IPs
sudo fail2ban-client status sshd
```

## First Boot

### Network Configuration
```bash
# Check current network config
ip addr show

# If using DHCP (automatic), it should already work
ip route show   # Check default gateway

# Static IP configuration (if needed)
sudo nano /etc/netplan/00-installer-config.yaml

# Example static config:
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.20/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]

# Apply changes
sudo netplan apply

# Verify
ip addr show
```

### System Time Sync
```bash
# Check time sync status
sudo timedatectl

# Should show "System clock synchronized: yes"

# Enable NTP if not already
sudo timedatectl set-ntp true

# Verify
sudo systemctl status systemd-timesyncd
```

### Storage Check
```bash
# Check disk usage
df -h

# Check filesystem health
sudo smartctl -a /dev/sda    # Requires smartmontools

# View partition layout
lsblk

# Check disk write performance
dd if=/dev/zero of=/tmp/test bs=1M count=1000 oflag=dsync
```

## System Updates

### Regular Update Schedule
```bash
# Check for updates
sudo apt-get update

# Preview what will update
sudo apt-get upgrade -s

# Apply updates
sudo apt-get upgrade -y

# Reboot if kernel updated
sudo reboot

# Schedule updates (optional automation)
sudo apt-get install unattended-upgrades

# Configure
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Enable Automatic Updates
```bash
# Install automatic updates
sudo apt-get install apt-listchanges

# Edit config
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

# Ensure these are set:
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

# Enable
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades
```

## Verification Steps

### Confirm Installation Success
```bash
# Run through checklist:
✓ System boots without USB drive
✓ Can login with password or SSH key
✓ Hostname correct: hostnamectl
✓ Network working: ping 8.8.8.8
✓ DNS working: nslookup google.com
✓ Disk space available: df -h
✓ No errors in log: sudo dmesg
✓ All services running: sudo systemctl status
✓ No pending updates: sudo apt-get update && apt-get upgrade -s
✓ System time correct: date
```

### Create System Snapshot
```bash
# For VMs, take snapshot after successful install
# For physical machines, backup full disk

# Example for VM (if using Proxmox)
sudo proxmox-backup-client backup
```

## Common Issues

### Issue: Network not working after install
```bash
# Check interface is up
ip link show

# If not up:
sudo ip link set eth0 up

# Check IP assignment
ip addr show

# If no IP and using DHCP:
sudo dhclient eth0

# Restart networking
sudo systemctl restart networking
```

### Issue: Can't SSH in
```bash
# Check SSH is running
sudo systemctl status ssh

# Check firewall allows SSH
sudo ufw status verbose

# Check SSH listening
sudo ss -tulpn | grep 22

# Verify SSH config
sudo sshd -t

# Check logs for errors
sudo journalctl -u ssh -n 20
```

### Issue: Package manager errors
```bash
# Fix broken packages
sudo apt --fix-broken install

# Clean package cache
sudo apt clean
sudo apt autoclean

# Update package list
sudo apt update --fix-missing
```

### Issue: Slow system after install
```bash
# Check for background tasks
top

# Check disk usage
df -h
du -sh ~

# Check network
ethtool eth0

# Install OS might still be initializing
# Wait 5-10 minutes and check again
```

## Best Practices

- Write down root/sudo passwords in secure location
- Use SSH keys instead of passwords for remote access
- Enable firewall immediately after SSH access works
- Set static IPs for servers (not DHCP)
- Document all configuration changes
- Schedule regular updates
- Verify all critical services after updates
- Keep system time synchronized
- Monitor disk space regularly
- Maintain offline backup of critical configs

---

✅ OS installation guide complete - solid foundation for your homelab services
