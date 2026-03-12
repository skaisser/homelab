# 🛡️ Security Guidelines & Hardening #best-practices #security #hardening #guidelines

Comprehensive security approach for protecting data, services, and infrastructure in your homelab.

## Table of Contents
1. [Defense in Depth](#defense-in-depth)
2. [Network Segmentation](#network-segmentation)
3. [Access Control](#access-control)
4. [Secrets Management](#secrets-management)
5. [SSL/TLS Everywhere](#ssltls-everywhere)
6. [Regular Updates](#regular-updates)
7. [Intrusion Monitoring](#intrusion-monitoring)
8. [VPN for Remote Access](#vpn-for-remote-access)
9. [Container Security](#container-security)
10. [Backup Encryption](#backup-encryption)

## Defense in Depth

### Layered Security Approach
```
Layer 1: Network Edge
- ISP/Modem firewall
- Router firewall

Layer 2: Host Firewall
- UFW/iptables per host
- Default deny policy

Layer 3: Application Level
- Web server (nginx) auth
- Database user permissions
- Service-specific access

Layer 4: Data Level
- File permissions
- Encryption at rest
- Encrypted transport

Example: Accessing database
1. Network: Port blocked by firewall unless from trusted VLAN
2. Host: Database server firewall allows only app server
3. Database: User account with minimal permissions
4. Data: Connections encrypted, queries logged
```

### Example Complete Security Stack
```bash
# Secure web service setup:

# 1. Firewall restricts to HTTPS only
sudo ufw allow 443/tcp
sudo ufw deny 8080/tcp

# 2. nginx listens on internal port, uses reverse proxy
# Config: listen 127.0.0.1:8080 (internal only)

# 3. App runs as unprivileged user
ps aux | grep appname
# root nobody 1234 0.0 0.1 ... /app/service

# 4. Database requires strong password + SSL
mysql -u appuser -p -h dbhost --ssl-mode=REQUIRED

# 5. Logs captured and monitored
tail -f /var/log/app/access.log | grep ERROR

# 6. Backup encrypted
gpg --encrypt backup.sql
```

## Network Segmentation

### Isolate by Trust Level
```
High Trust (Management)
- Your devices
- Admin access
- Less restricted

Medium Trust (Services)
- Homelab servers
- Internal services only
- Standard protection

Low Trust (Guest/IoT)
- Guest network
- IoT devices
- Heavily restricted
```

### Firewall Rules Between Segments
```bash
# Example with VLANs:

# Management can access everything
sudo ufw allow from 10.1.0.0/24 to any

# Services can talk to databases
sudo ufw allow from 10.2.0.0/24 to 10.3.0.0/24 port 3306

# Guest CANNOT access services
sudo ufw deny from 10.5.0.0/24 to 10.2.0.0/24

# IoT can access storage only
sudo ufw allow from 10.6.0.0/24 to 10.4.0.0/24 port 2049
sudo ufw deny from 10.6.0.0/24 to 10.2.0.0/24

# Default deny everything else
sudo ufw default deny incoming
```

### Network Diagram with Security
```
Internet
    |
[Firewall - pfSense]
    |
    +-- Management (10.1.0.0/24) - Restricted access
    |      (Router, switches, management tools)
    |
    +-- Production (10.2.0.0/24) - Medium trust
    |      (Hypervisors, services)
    |      Firewall rules: Storage OK, DB OK, IoT blocked
    |
    +-- Database (10.3.0.0/24) - Low trust
    |      Only accessible from Production
    |
    +-- Storage (10.4.0.0/24) - Low trust
    |      Only accessible from Production
    |
    +-- Guest (10.5.0.0/24) - No trust
    |      Can reach internet, not internal services
    |
    +-- IoT (10.6.0.0/24) - No trust
    |      Can reach storage only, not services
```

## Access Control

### Principle of Least Privilege
```bash
# File permissions example:
# ❌ Bad: Service can read all files
chmod 644 /etc/app/config.conf
chmod 755 /etc/app/

# ✓ Good: Service can only read its config
sudo chown appuser:appgroup /etc/app/config.conf
chmod 400 /etc/app/config.conf
chmod 500 /etc/app/  # Read and execute only

# Database user permissions:
# ❌ Bad: User can access all databases
GRANT ALL ON *.* TO 'appuser'@'appserver';

# ✓ Good: User can only access needed database
GRANT SELECT, INSERT, UPDATE ON myapp.* TO 'appuser'@'appserver';
REVOKE ALL ON *.* FROM 'appuser'@'appserver';

# Service capabilities (Linux):
# ❌ Bad: Service runs as root
sudo systemctl edit myapp
# User=root

# ✓ Good: Service runs as unprivileged user
sudo systemctl edit myapp
# User=myappuser
# Group=myappgroup
```

### SSH Key Management
```bash
# Generate keys with descriptive names
ssh-keygen -t ed25519 -C "homelab-admin-key-2024" -f ~/.ssh/homelab_admin

# Protect with strong passphrase
ssh-keygen -t ed25519 -C "key" -f ~/.ssh/id -N "MyLongPassphrase123!"

# Use ssh-agent to cache passphrase
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/homelab_admin
# Now can use key without re-entering passphrase

# Keep separate keys for different purposes
~/.ssh/homelab_admin         # For homelab
~/.ssh/github_personal       # For GitHub personal
~/.ssh/github_work           # For GitHub work

# In ~/.ssh/config:
Host homelab-1
    IdentityFile ~/.ssh/homelab_admin

Host github.com
    IdentityFile ~/.ssh/github_personal

Host github-work.com
    HostName github.com
    IdentityFile ~/.ssh/github_work
```

### Service Account Security
```bash
# Create unprivileged service account
sudo useradd -r -s /bin/false -d /var/lib/appname appname

# Set permissions strictly
sudo chown appname:appname /var/lib/appname
sudo chmod 700 /var/lib/appname
sudo chown appname:appname /etc/appname/config.conf
sudo chmod 600 /etc/appname/config.conf

# Allow service to restart itself via sudo (if needed)
echo "appname ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart appname" | \
  sudo tee /etc/sudoers.d/appname-restart
sudo chmod 440 /etc/sudoers.d/appname-restart

# Verify no login possible
sudo -u appname bash
# Should fail: "This account is currently not available"
```

## Secrets Management

### Handle Passwords Securely
```bash
# ❌ Bad: Password in config file as plain text
cat /etc/app/config.conf
database_password = mypassword123

# ✓ Good: Use environment variables
cat /etc/app/config.conf
database_password = ${DB_PASSWORD}

# Set in systemd service
sudo systemctl edit myapp
# [Service]
# Environment="DB_PASSWORD=mypassword123"

# Or use dedicated secrets manager
# Option 1: Hashicorp Vault
vault kv put secret/myapp/database password=mypassword123

# Option 2: docker-compose secrets
secrets:
  db_password:
    file: /run/secrets/db_password
```

### Database Credentials
```bash
# Store securely in ~/.my.cnf (MySQL)
cat ~/.my.cnf
[client]
user=myappuser
password=mypassword
host=localhost

# Restrict permissions
chmod 600 ~/.my.cnf

# Use in scripts without exposing password
mysql < backup.sql

# PostgreSQL ~/.pgpass
cat ~/.pgpass
localhost:5432:mydb:appuser:mypassword

chmod 600 ~/.pgpass

# In Docker:
# Use docker secrets or environment files
docker run -e DB_PASSWORD_FILE=/run/secrets/db_password ...
```

### API Keys and Tokens
```bash
# ❌ Bad: Key in environment variable shown in ps output
ps aux | grep myapp
... APP_API_KEY=sk-1234567890 ...

# ✓ Good: Read from file with restricted access
cat /etc/myapp/api.key
sk-1234567890

chmod 400 /etc/myapp/api.key
chown myapp:myapp /etc/myapp/api.key

# In app code:
api_key = open('/etc/myapp/api.key').read().strip()

# Or use secrets manager
vault kv get secret/myapp/api
```

## SSL/TLS Everywhere

### Certificate Sources
```bash
# Option 1: Let's Encrypt (Recommended, Free)
sudo apt-get install certbot

sudo certbot certonly --webroot -w /var/www/html -d mydomain.com

# Option 2: Self-signed (For internal only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/self-signed.key \
  -out /etc/ssl/certs/self-signed.crt

# Option 3: Internal CA (Best for homelab)
# Create CA once, sign multiple certs with it
```

### nginx HTTPS Setup
```nginx
# /etc/nginx/sites-available/mysite

server {
    listen 80;
    server_name mydomain.com;
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name mydomain.com;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/mydomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mydomain.com/privkey.pem;

    # Strong cipher suites
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # HSTS header (tell browsers to always use HTTPS)
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://backend:8080;
    }
}
```

### Certificate Renewal Automation
```bash
# Certbot creates systemd timer automatically
sudo systemctl list-timers | grep certbot

# Check renewal manually works
sudo certbot renew --dry-run

# View renewal logs
sudo journalctl -u certbot.timer
sudo journalctl -u certbot.service

# Reload nginx after renewal (if needed)
# Already handled by certbot hooks in:
# /etc/letsencrypt/renewal/mydomain.com.conf
```

## Regular Updates

### Automatic Update Strategy
```bash
# System updates
sudo apt-get update
sudo apt-get upgrade -y

# Docker image updates
docker images | grep latest | awk '{print $1}' | xargs -I {} docker pull {}

# Container restart
docker-compose pull
docker-compose up -d

# Application updates
# Check release pages regularly
# Subscribe to security mailing lists
```

### Patching Critical Vulnerabilities
```bash
# Monitor security advisories:
# 1. Ubuntu security notices: https://security.ubuntu.com/
# 2. Docker Hub advisories
# 3. Application-specific mailing lists

# Emergency patching process:
# 1. Test patch in staging environment
# 2. Schedule maintenance window
# 3. Create snapshot/backup first
# 4. Apply patch
# 5. Verify services still work
# 6. Monitor logs for issues
```

## Intrusion Monitoring

### Log Monitoring
```bash
# View recent authentication attempts
sudo tail -f /var/log/auth.log | grep -i "failed\|accepted"

# Check for unusual processes
ps aux | grep -v "/root\|/bin\|/sbin\|/lib"

# Monitor network connections
sudo watch -n 1 'ss -tulpn'

# Check for modified system files
sudo debsums -c

# Search for rootkits
sudo apt-get install chkrootkit
sudo chkrootkit
```

### Set Up Audit Logging
```bash
# Install auditd
sudo apt-get install auditd

# Monitor file access
sudo auditctl -w /etc/passwd -p wa -k passwd_changes

# Monitor system calls
sudo auditctl -a always,exit -S execve -k exec_logging

# View logs
sudo ausearch -k passwd_changes

# Make persistent
sudo nano /etc/audit/rules.d/audit.rules
-w /etc/passwd -p wa -k passwd_changes

# Restart auditd
sudo systemctl restart auditd
```

## VPN for Remote Access

### WireGuard Setup (Recommended)
```bash
# Install WireGuard
sudo apt-get install wireguard

# Generate keys
wg genkey | tee private.key | wg pubkey > public.key

# Create server interface
sudo nano /etc/wireguard/wg0.conf

[Interface]
PrivateKey = <SERVER_PRIVATE_KEY>
Address = 10.9.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 10.9.0.2/32

# Bring up
sudo wg-quick up wg0

# Enable on boot
sudo systemctl enable wg-quick@wg0

# Client config
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.9.0.2/24
DNS = 10.1.0.10

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = myhomelab.duckdns.org:51820
AllowedIPs = 10.0.0.0/8
```

### Firewall for VPN
```bash
# Open VPN port
sudo ufw allow 51820/udp

# Allow VPN traffic through firewall
sudo ufw allow from 10.9.0.0/24

# Add policy to route VPN traffic
# In pfSense/OPNsense GUI:
# Rules tab → VPN rules allowing 10.9.0.0/24 access
```

## Container Security

### Secure Docker Running
```bash
# Run containers with security options
docker run \
  --security-opt=no-new-privileges:true \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --read-only \
  -v /tmp:/tmp \
  myapp:latest

# Or in docker-compose:
services:
  app:
    image: myapp:latest
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    volumes:
      - /tmp:/tmp
```

### Image Scanning
```bash
# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image myapp:latest

# Or use Snyk
snyk test --docker myapp:latest

# Build images from trusted base images
# ✓ Good: FROM ubuntu:24.04
# ✓ Good: FROM debian:bookworm-slim
# ❌ Avoid: FROM myregistry/unknown-base

# Scan before pushing
docker scan myapp:latest
```

## Backup Encryption

### Encrypting Backups
```bash
# Using GPG for encryption
tar czf - /data | gpg --encrypt -r "your-email@example.com" > backup.tar.gz.gpg

# Decrypt later
gpg --decrypt backup.tar.gz.gpg | tar xzf -

# Using OpenSSL
tar czf - /data | openssl enc -aes-256-cbc -e > backup.tar.gz.enc

# Decrypt
openssl enc -aes-256-cbc -d -in backup.tar.gz.enc | tar xzf -
```

### Storage Security
```bash
# Backup location options:
✓ External drive (encrypted)
✓ Cloud storage (encrypted before upload)
✓ Separate physical location
✓ NAS with RAID (not redundant!)

# ❌ Wrong:
- Same disk as primary data (RAID not backup)
- Unencrypted external drive
- Only one backup copy
```

## Best Practices Summary

- Implement defense in depth, not single layer
- Use network segmentation to limit lateral movement
- Apply principle of least privilege everywhere
- Encrypt data in transit and at rest
- Keep systems updated regularly
- Monitor logs for suspicious activity
- Use strong authentication (SSH keys, not passwords)
- Maintain secure backups
- Document security procedures
- Review security posture quarterly

---

✅ Security guidelines complete - comprehensive protection for your homelab
