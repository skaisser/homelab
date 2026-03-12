# 🔐 Bitwarden: Self-Hosted Password Management #self-hosted #bitwarden #vaultwarden #security

Your own password vault. Vaultwarden provides lightweight, self-hosted password management with cross-platform clients and zero tracking.

## Table of Contents
1. [Why Self-Hosted Password Management](#why-self-hosted-password-management)
2. [Vaultwarden Overview](#vaultwarden-overview)
3. [Docker Compose Deployment](#docker-compose-deployment)
4. [Initial Setup](#initial-setup)
5. [HTTPS Configuration](#https-configuration)
6. [Admin Panel](#admin-panel)
7. [User Management](#user-management)
8. [Database Backup](#database-backup)
9. [Client Setup](#client-setup)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)
12. [Additional Resources](#additional-resources)

## Why Self-Hosted Password Management

### Security Advantages

- **No cloud dependency**: Your passwords never leave your network
- **Encryption**: All data encrypted end-to-end
- **Audit trail**: Full control and visibility
- **No tracking**: No analytics, no telemetry
- **Compliance**: Meet HIPAA, GDPR, SOC 2 requirements

### Comparison

| Aspect | Bitwarden Cloud | Vaultwarden | LastPass |
|--------|-----------------|-------------|----------|
| Cost | $10/year | Free (self-hosted) | $36/year |
| Encryption | E2E | E2E | E2E |
| Privacy | Cloud-based | Self-hosted | Cloud-based |
| Open Source | Core | Full | No |
| Source audit | Yes | Yes | No |

## Vaultwarden Overview

Vaultwarden is a lightweight, API-compatible Bitwarden implementation written in Rust.

**Advantages:**
- Single binary deployment
- Minimal resource usage (50MB RAM)
- Fully compatible with Bitwarden clients
- Community maintained
- Supports everything except organization features

**Limitations:**
- No Teams/Organizations (single-user focus)
- No Enterprise SSO
- Community support only (vs Bitwarden SaaS support)

## Docker Compose Deployment

### Minimal Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    ports:
      - "8000:80"
      - "3012:3012"
    environment:
      - DOMAIN=https://vault.example.com
      - SIGNUPS_ALLOWED=false
      - INVITATIONS_ALLOWED=true
      - SEND_PURGE=30
      - LOG_LEVEL=info
      - LOG_FILE=/data/vaultwarden.log
      - ADMIN_TOKEN=GenerateTokenHere
      - DATABASE_URL=sqlite:/data/db.sqlite3
    volumes:
      - /opt/vaultwarden/data:/data
      - /opt/vaultwarden/icons:/data/icon_cache
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### With PostgreSQL (Production)

For multiple users:

```yaml
version: '3.8'
services:
  vaultwarden-db:
    image: postgres:15-alpine
    container_name: vaultwarden-db
    environment:
      - POSTGRES_DB=vaultwarden
      - POSTGRES_USER=vaultwarden
      - POSTGRES_PASSWORD=secureDbPassword456
      - POSTGRES_INITDB_ARGS=--encoding=UTF8
    volumes:
      - /opt/vaultwarden/db:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - homelab

  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    depends_on:
      - vaultwarden-db
    ports:
      - "8000:80"
      - "3012:3012"
    environment:
      - DOMAIN=https://vault.example.com
      - DATABASE_URL=postgresql://vaultwarden:secureDbPassword456@vaultwarden-db:5432/vaultwarden
      - SIGNUPS_ALLOWED=false
      - INVITATIONS_ALLOWED=true
      - ADMIN_TOKEN=GenerateTokenHere
      - LOG_LEVEL=info
    volumes:
      - /opt/vaultwarden/data:/data
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### Setup Instructions

Generate admin token (required):

```bash
# Generate secure token
openssl rand -base64 32
# Output: Hg3aB8fX2kL9pM5nV8wQ1xZ7cR4dF6sT9uY2lP0oJ3iW

# Or use Bitwarden login page
# (shown in URL after first admin login)
```

Create directories and start:

```bash
mkdir -p /opt/vaultwarden/{data,icons,db}
sudo chown -R 1000:1000 /opt/vaultwarden

docker-compose up -d

# Verify
docker-compose logs -f vaultwarden
```

Access Vaultwarden:
```
http://localhost:8000
```

## Initial Setup

### Disable Signups

By default, signups are disabled. To enable (only while adding initial users):

```yaml
environment:
  - SIGNUPS_ALLOWED=true
```

Then disable after all users created:

```bash
docker-compose down
# Edit docker-compose.yml: SIGNUPS_ALLOWED=false
docker-compose up -d
```

### Create Master Password

1. Click "Create account"
2. Email: your@email.com (any email)
3. Master password: Strong passphrase (20+ characters)
4. **Save recovery codes** offline
5. Click "Create account"

Recovery codes:
```
Save offline in secure location:
- Printed paper
- Encrypted USB
- Hardware wallet
```

### First Login

1. Login with created account
2. Navigate to organization settings
3. Customize vault name
4. Optional: Create collections (folders)

## HTTPS Configuration

HTTPS is mandatory for Vaultwarden (required by browsers).

### Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl http2;
    server_name vault.example.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    location / {
        proxy_pass http://vaultwarden:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /notifications/hub {
        proxy_pass http://vaultwarden:3012;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /notifications/hub/negotiate {
        proxy_pass http://vaultwarden:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Caddy Configuration

```
vault.example.com {
    reverse_proxy localhost:8000 {
        header_uri X-Forwarded-Proto https
    }

    reverse_proxy /notifications/hub localhost:3012 {
        header_uri X-Forwarded-Proto https
        websocket
    }
}
```

### Update Docker-Compose

```yaml
environment:
  - DOMAIN=https://vault.example.com
  - SIGNUPS_ALLOWED=false
  - LOG_LEVEL=info
```

## Admin Panel

Access admin panel:
```
https://vault.example.com/admin/
```

### Authentication

First visit prompts for admin token:
- Enter token generated during setup
- Access granted for 2 hours (auto-logout)

### Admin Panel Features

**Users:**
- List all users
- Delete users (irreversible)
- Reset user password
- View storage usage

**Organizations:**
- Manage organization settings
- Configure policies

**Settings:**
- Mail configuration (for invitations)
- Backup and restore

## User Management

### Add Users (Invitation Method)

1. Share vault link: `https://vault.example.com`
2. User creates account
3. You send invitations from admin panel

Or via CLI:

```bash
docker-compose exec vaultwarden vaultwarden hash "Master_Password"
```

### Create Manual User

Via admin panel:
1. Users → Add new user
2. Enter email
3. Set temporary password
4. Share credentials securely

### Configure Mail (Optional)

For password reset emails and invitations:

Add to docker-compose.yml:

```yaml
environment:
  - DOMAIN=https://vault.example.com
  - MAIL_FROM=vault@example.com
  - MAIL_HOST=smtp.gmail.com
  - MAIL_PORT=587
  - MAIL_SECURITY=starttls
  - MAIL_USERNAME=your-email@gmail.com
  - MAIL_PASSWORD=app-specific-password
```

## Database Backup

### SQLite Backup

Backup the database file:

```bash
# Stop Vaultwarden
docker-compose down

# Backup
cp /opt/vaultwarden/data/db.sqlite3 \
   /opt/vaultwarden/backups/db_$(date +%Y%m%d).sqlite3

# Restart
docker-compose up -d
```

Automated backup:

```bash
#!/bin/bash
# backup-vaultwarden.sh
BACKUP_DIR="/opt/vaultwarden/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup database
cp /opt/vaultwarden/data/db.sqlite3 \
   "$BACKUP_DIR/vaultwarden_db_$DATE.sqlite3"

# Backup data directory
tar -czf "$BACKUP_DIR/vaultwarden_$DATE.tar.gz" \
  /opt/vaultwarden/data

# Delete backups older than 30 days
find "$BACKUP_DIR" -name "vaultwarden_*" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR"
```

Schedule cron:

```bash
# Backup daily at 3 AM
0 3 * * * /path/to/backup-vaultwarden.sh
```

### PostgreSQL Backup

```bash
docker-compose exec vaultwarden-db pg_dump \
  -U vaultwarden vaultwarden > \
  /opt/vaultwarden/backups/vaultwarden_$(date +%Y%m%d).sql
```

## Client Setup

### Web Vault

Access web version:
```
https://vault.example.com
```

Features:
- Full vault management
- Credential storage
- Secure notes
- Emergency access (designate trusted contact)

### Android

1. Download from Play Store: "Bitwarden"
2. Settings → Server → Self-hosted
3. Server URL: https://vault.example.com
4. Login with email and master password

### iOS

1. Download from App Store: "Bitwarden"
2. Settings → Server URL
3. Enter: https://vault.example.com
4. Login with credentials

### Browser Extensions

Available for Chrome, Firefox, Safari, Edge:

1. Download extension from browser store
2. Click extension icon
3. Settings → Vault → Server URL
4. Enter: https://vault.example.com
5. Login once
6. Auto-fill passwords in login forms

### Desktop (Windows/Mac/Linux)

1. Download from https://bitwarden.com/download/
2. Install application
3. Open → Settings → Server
4. Custom server URL: https://vault.example.com
5. Login and sync

### Command-Line Tool

For scripting and automation:

```bash
# Install
npm install -g @bitwarden/cli

# Login
bw login your-email@example.com

# Prompt for master password

# List items
bw list items

# Get password
bw get password "Gmail"
```

## Troubleshooting

### Users can't login
```bash
# Check database
docker-compose exec vaultwarden-db \
  psql -U vaultwarden vaultwarden -c "SELECT email FROM users;"

# Restart Vaultwarden
docker-compose restart vaultwarden

# Check logs
docker-compose logs -f vaultwarden | grep -i error
```

### HTTPS certificate errors
```bash
# Verify certificate
curl -I https://vault.example.com
# Should show green SSL

# If self-signed, add exception in client
# Or use Let's Encrypt for automatic renewal
```

### Notifications/WebSocket not working
```bash
# Check port 3012
curl http://localhost:3012

# Verify nginx configuration includes /notifications/hub
# Check firewall allows port 443 (HTTPS)
```

### Database size growing too large
```bash
# Check icon cache
du -sh /opt/vaultwarden/data/icon_cache

# Clear old icons
docker-compose exec vaultwarden rm -rf /data/icon_cache/*

# Vacuum database (SQLite)
docker-compose exec vaultwarden sqlite3 /data/db.sqlite3 "VACUUM;"
```

## Best Practices

1. **Master Password**: 20+ characters, unique, not reused
2. **Recovery Codes**: Print and store offline
3. **Backups**: Daily automated backups with offsite copy
4. **HTTPS**: Always use SSL/TLS
5. **Signups**: Keep disabled after initial setup
6. **Updates**: Monthly updates, test in staging first
7. **Audit Logs**: Monitor admin panel activity
8. **Two-Factor**: Enable 2FA for email

## Additional Resources

- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Bitwarden Documentation](https://bitwarden.com/help/)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [r/Vaultwarden](https://reddit.com/r/vaultwarden)
- [Bitwarden Forum](https://community.bitwarden.com)

---

✅ **Self-hosted password vault deployed securely with encrypted storage!**
