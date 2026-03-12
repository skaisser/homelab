# 🔒 Initial Security Setup Guide #setup #security #ssh #firewall #basics

Essential security hardening steps for protecting your homelab from day one.

## Table of Contents
1. [Security Mindset](#security-mindset)
2. [SSH Hardening](#ssh-hardening)
3. [Firewall Setup](#firewall-setup)
4. [Fail2ban Installation](#fail2ban-installation)
5. [Automatic Updates](#automatic-updates)
6. [User Management](#user-management)
7. [Network Segmentation](#network-segmentation)
8. [What NOT to Expose](#what-not-to-expose)
9. [Security Verification](#security-verification)
10. [Incident Response](#incident-response)

## Security Mindset

### Security Principles
```
1. Defense in Depth
   - Multiple layers of protection
   - Compromising one layer doesn't give full access
   - Example: Firewall + SSH hardening + fail2ban

2. Principle of Least Privilege
   - Users/services only get what they need
   - No admin access for regular users
   - Services run as unprivileged users

3. Default Deny
   - Block everything by default
   - Only explicitly allow what's needed
   - Easier to manage than denying bad things

4. Keep It Simple
   - Complex systems are hard to secure
   - Understand your security setup
   - Don't use features you don't need
```

### Common Threats
```
Local Network Threats:
- Compromised device on network gains access
- Lateral movement through unprotected services
- Rogue WiFi AP

Remote Threats:
- SSH brute force attacks
- Exposed services on internet
- Unpatched vulnerabilities
- Social engineering

Internal Threats:
- Guest with malicious intent
- Compromised container escaping
- Neighbor WiFi interference
```

## SSH Hardening

### Disable Root Login
```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Find and verify:
# PermitRootLogin no

# If commented out, uncomment
# If set to yes, change to no

# Save file (Ctrl+O, Enter, Ctrl+X)

# Restart SSH
sudo systemctl restart sshd

# Verify change
sudo grep PermitRootLogin /etc/ssh/sshd_config
```

### Key-Based Authentication Setup
```bash
# On LOCAL machine (your laptop):
# Generate keypair
ssh-keygen -t ed25519 -C "homelab-key" -f ~/.ssh/homelab_rsa -N "passphrase"

# Options explained:
# -t ed25519: Modern, secure algorithm
# -C: Comment for key identification
# -f: Filename to save
# -N: Passphrase (use strong one for local security)

# Copy public key to server
ssh-copy-id -i ~/.ssh/homelab_rsa username@homelab-1

# Or manually:
cat ~/.ssh/homelab_rsa.pub | ssh username@homelab-1 \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Set correct permissions on server
ssh username@homelab-1 'chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'

# Test key login
ssh -i ~/.ssh/homelab_rsa username@homelab-1
# Should NOT ask for password
```

### Disable Password Authentication
```bash
# Critical: Only do this after key login works!
# Test from NEW terminal to avoid lockout

# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Change these lines:
PasswordAuthentication no
PubkeyAuthentication yes

# Optional improvements:
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
MaxSessions 5

# Save file

# Verify config syntax before restart!
sudo sshd -t
# Should return with no output (success)

# Restart SSH
sudo systemctl restart sshd

# TEST FROM NEW TERMINAL:
ssh -i ~/.ssh/homelab_rsa username@homelab-1
# Should work without password prompt
```

### Change SSH Port (Optional)
```bash
# Reduces noise from automated scanners
# Not required, but useful

sudo nano /etc/ssh/sshd_config

# Find: #Port 22
# Change to: Port 2222

# Verify syntax
sudo sshd -t

# Restart
sudo systemctl restart sshd

# Configure firewall for new port
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp    # Remove old rule

# Create SSH config entry on local machine
# ~/.ssh/config:
Host homelab-1
    HostName 192.168.1.20
    User username
    Port 2222
    IdentityFile ~/.ssh/homelab_rsa

# Now SSH with just: ssh homelab-1
```

### SSH Config Best Practices
```bash
# Example hardened /etc/ssh/sshd_config:

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no

# Connection limits
MaxSessions 10
MaxAuthTries 3
LoginGraceTime 20

# Security
X11Forwarding no
PrintMotd no
Compression delayed
ClientAliveInterval 300
ClientAliveCountMax 3

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# More paranoid:
# AllowUsers username@192.168.1.0/24
# AllowUsers username@10.0.0.0/8
```

## Firewall Setup

### UFW (Uncomplicated Firewall) Basics
```bash
# Check status
sudo ufw status

# Enable firewall
sudo ufw enable

# Verify enabled
sudo systemctl is-active ufw

# Check all rules
sudo ufw status verbose

# List rules with numbers
sudo ufw status numbered
```

### UFW Core Rules
```bash
# CRITICAL: Allow SSH before enabling!
sudo ufw allow 22/tcp    # Or custom port

# Allow incoming HTTP/HTTPS
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Allow DNS (if running DNS service)
sudo ufw allow 53        # DNS (TCP and UDP)

# Allow from specific IP only
sudo ufw allow from 192.168.1.100 to any port 8080

# Allow from subnet
sudo ufw allow from 192.168.1.0/24 to any port 3306

# Deny specific port
sudo ufw deny 23/tcp     # Telnet

# Delete rule (use number from status numbered)
sudo ufw delete 2        # Deletes rule #2

# Reset all rules
sudo ufw reset           # Careful! Requires re-enable
```

### UFW Example Configuration
```bash
# Scenario: Homelab server running web + SSH

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow from local network only (example)
sudo ufw allow from 192.168.1.0/24 to any port 8080

# Enable
sudo ufw enable

# Verify
sudo ufw status verbose
```

### Logging and Monitoring
```bash
# Enable firewall logging
sudo ufw logging on

# Set log level (low, medium, high, full)
sudo ufw logging medium

# View logs
sudo tail -f /var/log/ufw.log

# Search for blocked packets
grep "UFW BLOCK" /var/log/ufw.log | head -20

# View dropped connections
grep "UFW BLOCK" /var/log/ufw.log | awk '{print $NF}' | sort | uniq -c | sort -rn
```

## Fail2ban Installation

### Installation and Setup
```bash
# Install fail2ban
sudo apt-get install fail2ban

# Start service
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Verify running
sudo systemctl status fail2ban
sudo fail2ban-client status
```

### Configuration
```bash
# Copy default config to local override
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit local config (overrides defaults)
sudo nano /etc/fail2ban/jail.local

# Key settings:
[DEFAULT]
ignoreip = 127.0.0.1/8 192.168.1.100  # Don't ban your IP!
bantime = 3600                         # Ban for 1 hour
findtime = 600                         # Look back 10 minutes
maxretry = 5                           # Ban after 5 attempts

# SSH protection
[sshd]
enabled = true
port = ssh                # Or 2222 if changed
logpath = /var/log/auth.log
maxretry = 3              # Ban after 3 failed attempts
bantime = 1800            # Ban for 30 minutes
```

### Monitor Fail2ban
```bash
# View all jails
sudo fail2ban-client status

# View specific jail status
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client status sshd | grep "Banned IP"

# Manually ban IP (testing)
sudo fail2ban-client set sshd banip 192.168.1.50

# Manually unban IP
sudo fail2ban-client set sshd unbanip 192.168.1.50

# View fail2ban logs
sudo tail -f /var/log/fail2ban.log
```

## Automatic Updates

### Enable Unattended Upgrades
```bash
# Install package
sudo apt-get install unattended-upgrades apt-listchanges

# Enable
sudo dpkg-reconfigure -plow unattended-upgrades

# Verify enabled
systemctl is-enabled unattended-upgrades
systemctl is-active unattended-upgrades

# View config
cat /etc/apt/apt.conf.d/50unattended-upgrades
```

### Configure Auto-Restart
```bash
# Edit config
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

# Find and uncomment:
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

# This restarts at 2 AM if kernel updates
# Adjust time to off-peak hours
```

### Monitor Updates
```bash
# Check what updates would be applied
sudo unattended-upgrade --dry-run

# View update logs
cat /var/log/unattended-upgrades/unattended-upgrades.log

# Recent updates
ls -lt /var/log/apt/ | head -10
```

## User Management

### Create Service User (Example)
```bash
# Create user for a service (no login)
sudo useradd -r -s /bin/false servicename

# Explanation:
# -r: System user (UID < 1000)
# -s /bin/false: No login shell

# Verify
id servicename

# This user can't login but can own files/processes
```

### sudo Without Password (Careful!)
```bash
# WARNING: Only for specific commands you trust!

# Allow user to run specific command without password:
sudo visudo

# Add this line:
username ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx

# This allows: sudo systemctl restart nginx
# Without entering password

# Limit to specific commands only
# Never allow: ALL with NOPASSWD
```

### Remove Unnecessary Users
```bash
# List all users
cut -d: -f1 /etc/passwd

# Check when last logged in
lastlog

# Remove unused user
sudo userdel -r username
# -r: Also remove home directory
```

## Network Segmentation

### Firewall Between Networks
```
Not everyone should access everything.
Create zones with different access levels:

Trusted:
- Your own devices
- Family devices
- Known services

Untrusted:
- Guest WiFi
- IoT devices
- Containers

Rule of thumb:
```

### UFW Zone Rules
```bash
# Allow from trusted network only
sudo ufw allow from 192.168.1.0/24 to any port 3306

# Deny specific device
sudo ufw deny from 10.0.0.50 to any port 8080

# All traffic from IoT VLAN only to storage
sudo ufw allow from 10.6.0.0/24 to any port 2049  # NFS

# Deny all to sensitive port by default
sudo ufw default deny to 10.3.0.0/24 port 3306
sudo ufw allow from 10.2.0.0/24 to 10.3.0.0/24 port 3306
```

## What NOT to Expose

### Services That Should NOT Be Internet-Facing
```
❌ DO NOT EXPOSE:
- Databases (MySQL, PostgreSQL, MongoDB)
- Kubernetes API
- VMware vCenter
- Router management interface
- Home Assistant
- Plex (without reverse proxy)
- Any service without authentication

✓ SAFE WITH CAUTION:
- Web applications (behind HTTPS)
- SSH (with key auth only, non-standard port)
- VPN access point
- Reverse proxy (but not backend services)
```

### Example Bad Configuration
```bash
# ❌ BAD - Exposes database to entire internet
sudo ufw allow 3306/tcp

# ✓ GOOD - Allow only from trusted source
sudo ufw allow from 192.168.1.0/24 to any port 3306

# ❌ BAD - Exposes SSH on default port to brutes
sudo ufw allow 22/tcp  # With PasswordAuthentication enabled

# ✓ GOOD - SSH hardened
sudo ufw allow 2222/tcp  # Non-standard port
# Plus: Key-only auth, fail2ban, logging
```

### Reverse Proxy Pattern (Safe Exposure)
```
Safe way to expose web services:

        Internet
            |
    [Reverse Proxy - Public]
    (nginx, Apache, Traefik)
            |
        [Firewall Rule]
            |
    [Backend Services - Private]
    (Plex, Home Assistant, etc.)

This allows:
- Public access to specific service
- Backend service hidden from internet
- SSL/authentication at proxy layer
- Easy to add, remove, or modify access
```

## Security Verification

### Run Security Checklist
```bash
# Verify firewall enabled
sudo ufw status | grep "Status: active"

# Verify SSH key auth only
sudo grep "PasswordAuthentication no" /etc/ssh/sshd_config

# Verify root login disabled
sudo grep "PermitRootLogin no" /etc/ssh/sshd_config

# Verify fail2ban running
sudo systemctl is-active fail2ban

# Verify no unnecessary services listening
sudo ss -tulpn

# Verify no unnecessary users
cut -d: -f1 /etc/passwd | wc -l  # Keep minimal

# Verify automatic updates enabled
systemctl is-enabled unattended-upgrades

# Verify system is up to date
sudo apt-get update && sudo apt-get upgrade -s  # Should show no upgrades
```

### Security Scan Tools
```bash
# Scan for open ports
sudo nmap localhost

# Check SSH configuration
sudo sshd -t -v

# View network connections
sudo ss -tulpn

# Check firewall rules
sudo ufw status verbose

# Verify service permissions
ls -la /etc/ssh/sshd_config
stat /etc/ssh/sshd_config
```

## Incident Response

### If Compromised
```bash
# 1. Isolate immediately
- Disconnect network if remote access
- Or change firewall rules to deny all

# 2. Don't delete evidence
- Keep logs intact for analysis
- Copy for investigation later

# 3. Change all passwords (from different machine)
# 4. Rotate SSH keys
# 5. Review recent changes
sudo journalctl --since "2 hours ago"
sudo grep -i fail /var/log/auth.log | tail -50

# 6. Full OS reinstall if unsure
# 7. Restore from last known good backup
```

### Monitoring for Intrusions
```bash
# Check for unauthorized SSH keys
cat ~/.ssh/authorized_keys

# View sudo usage
sudo journalctl _COMM=sudo -n 20

# Check for listening ports (unusual)
sudo ss -tulpn

# Search for unusual cron jobs
sudo crontab -l
sudo ls /etc/cron.d/

# Check for modified system files
sudo debsums -c

# View recent user activity
last -20
```

## Best Practices

- Never share SSH private keys
- Use passphrases on SSH keys
- Rotate keys periodically
- Monitor logs regularly
- Keep backups of configs
- Don't expose services unnecessarily
- Use firewall even on local network
- Keep SSH access restricted
- Document all security rules
- Review security regularly (quarterly)

---

✅ Initial security setup complete - protect your homelab from the start
