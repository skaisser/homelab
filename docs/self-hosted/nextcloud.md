# ☁️ Nextcloud: Personal Cloud Storage #self-hosted #nextcloud #cloud #storage

Your own Google Drive alternative. Nextcloud provides file sync, sharing, calendar, contacts, notes, and office apps—entirely under your control.

## Table of Contents
1. [Nextcloud Overview](#nextcloud-overview)
2. [Docker Compose Deployment](#docker-compose-deployment)
3. [Initial Configuration](#initial-configuration)
4. [Reverse Proxy Setup](#reverse-proxy-setup)
5. [Storage Configuration](#storage-configuration)
6. [Apps and Extensions](#apps-and-extensions)
7. [Performance Tuning](#performance-tuning)
8. [Backup Strategy](#backup-strategy)
9. [Security Hardening](#security-hardening)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)
12. [Additional Resources](#additional-resources)

## Nextcloud Overview

Nextcloud is an open-source file hosting platform. Features:

- **Files**: Sync, share, and organize files
- **Calendar**: CalDAV-compatible calendars
- **Contacts**: CardDAV address books
- **Notes**: Simple note-taking
- **Mail**: IMAP/POP3 email client
- **Deck**: Kanban boards
- **Talk**: Video conferencing
- **Office**: Edit documents (with Collabora Online)

System Requirements:
- PHP 8.1+
- Database (MySQL/MariaDB, PostgreSQL)
- 2GB RAM minimum (4GB+ recommended)
- 10GB storage minimum

## Docker Compose Deployment

### All-in-One Stack

Create `docker-compose.yml` with Nextcloud, MariaDB, and Redis:

```yaml
version: '3.8'
services:
  nextcloud-db:
    image: mariadb:10.6
    container_name: nextcloud-db
    environment:
      - MYSQL_ROOT_PASSWORD=securePassword123
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloudPassword456
      - TZ=America/New_York
    volumes:
      - /opt/nextcloud/db:/var/lib/mysql
    restart: unless-stopped
    networks:
      - homelab

  nextcloud-redis:
    image: redis:7-alpine
    container_name: nextcloud-redis
    restart: unless-stopped
    networks:
      - homelab

  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    depends_on:
      - nextcloud-db
      - nextcloud-redis
    ports:
      - "8080:80"
    environment:
      - MYSQL_HOST=nextcloud-db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloudPassword456
      - REDIS_HOST=nextcloud-redis
      - NEXTCLOUD_ADMIN_USER=admin
      - NEXTCLOUD_ADMIN_PASSWORD=adminPassword789
      - NEXTCLOUD_TRUSTED_DOMAINS=localhost 192.168.1.100 nextcloud.example.com
      - OVERWRITEPROTOCOL=https
      - OVERWRITEHOST=nextcloud.example.com
      - OVERWRITEWEBROOT=/
    volumes:
      - /opt/nextcloud/data:/var/www/html
      - /mnt/nextcloud/files:/var/www/html/data
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### Setup Instructions

```bash
# Create directories
mkdir -p /opt/nextcloud/{db,data}
mkdir -p /mnt/nextcloud/files
sudo chown -R 33:33 /opt/nextcloud /mnt/nextcloud

# Start stack
docker-compose up -d

# Wait for initialization (~60 seconds)
sleep 60

# Access Nextcloud
# http://localhost:8080
# Login: admin / adminPassword789
```

## Initial Configuration

### First Run Wizard

1. **Set Admin Account**: Already configured via environment variables
2. **Data Directory**: Pre-configured to `/var/www/html/data`
3. **Database**: MariaDB connection details in environment

### Post-Installation Setup

Access: http://localhost:8080/settings/admin/overview

1. **Settings → Admin → Security**:
   - Enable HTTPS requirement
   - Set security headers
   - Configure trusted proxies (if behind reverse proxy)

2. **Settings → Admin → Background Jobs**:
   - Change from AJAX to Cron
   - Configure cron job:

```bash
# Add to crontab
crontab -e

# Add line:
*/5 * * * * docker-compose -f /opt/docker-compose.yml exec -u www-data nextcloud php occ maintenance:mode --off && docker-compose -f /opt/docker-compose.yml exec -u www-data nextcloud php -f /var/www/html/cron.php
```

3. **Settings → Admin → Overview**:
   - Review recommended settings
   - Fix any warnings (memory limit, PHP settings, etc.)

## Reverse Proxy Setup

### Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name nextcloud.example.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    client_max_body_size 10G;

    location / {
        proxy_pass http://nextcloud:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;

        # WebDAV support
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
    }
}
```

### Caddy Configuration

```
nextcloud.example.com {
    reverse_proxy localhost:8080
}
```

### Configure Nextcloud for Proxy

Edit `/opt/nextcloud/data/config/config.php`:

```php
'overwrite.cli.url' => 'https://nextcloud.example.com/',
'overwritehost' => 'nextcloud.example.com',
'overwriteprotocol' => 'https',
'overwritewebroot' => '/',
'trusted_proxies' =>
  array (
    0 => '127.0.0.1',
    1 => '172.17.0.0/16',
  ),
```

Or via CLI:

```bash
docker-compose exec -u www-data nextcloud php occ config:system:set \
  overwrite.cli.url --value="https://nextcloud.example.com/"

docker-compose exec -u www-data nextcloud php occ config:system:set \
  overwritehost --value="nextcloud.example.com"

docker-compose exec -u www-data nextcloud php occ config:system:set \
  overwriteprotocol --value="https"
```

## Storage Configuration

### Local Storage (Default)

All files stored in `/mnt/nextcloud/files` on the host system.

```bash
# Monitor usage
du -sh /mnt/nextcloud/files

# Set disk quota per user
docker-compose exec -u www-data nextcloud php occ user:setting \
  username quota 100GB
```

### External Storage: SMB/CIFS

Share network drive via Nextcloud.

Install app:
```bash
docker-compose exec -u www-data nextcloud php occ app:enable files_external
```

Configure via UI:
1. Settings → Admin → External Storages
2. Click Add Storage → SMB/CIFS
3. Enter:
   - Folder name: Media
   - URL: `smb://192.168.1.50/shared`
   - Username/Password: SMB credentials
   - Available for: Select users/groups

### External Storage: S3

Store files in AWS S3 or compatible service (Minio).

```bash
docker-compose exec -u www-data nextcloud php occ app:enable \
  files_external
```

Configure:
1. Settings → Admin → External Storages
2. Add Storage → Amazon S3
3. Enter S3 credentials and bucket

## Apps and Extensions

### Essential Apps

Install via Settings → Apps:

1. **Calendar**: CalDAV calendar management
2. **Contacts**: CardDAV address books
3. **Notes**: Simple note-taking
4. **Tasks**: Task management with CalDAV
5. **News**: RSS feed reader

### Collaboration

1. **Collabora Online Integration**: Real-time document editing
   - Requires separate Collabora server
   - Or use CODE (Community Edition)

Install Collabora CODE:

```yaml
# Add to docker-compose.yml
collabora:
  image: collabora/code:latest
  container_name: collabora
  ports:
    - "9980:9980"
  environment:
    - domain=nextcloud.example.com
    - username=admin
    - password=collaboraPass123
  restart: unless-stopped
  networks:
    - homelab
```

Configure in Nextcloud:
1. Settings → Admin → Collabora Online
2. URL: https://collabora.example.com:9980

### Install Custom Apps

```bash
# Search Nextcloud App Store
# https://apps.nextcloud.com/

# Or install via CLI
docker-compose exec -u www-data nextcloud php occ app:install \
  appname
```

## Performance Tuning

### Redis Caching

Already configured in docker-compose.yml. Cache improvements:

Edit `/opt/nextcloud/data/config/config.php`:

```php
'memcache.local' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'redis' =>
  array (
    'host' => 'nextcloud-redis',
    'port' => 6379,
  ),
```

Or via CLI:

```bash
docker-compose exec -u www-data nextcloud php occ config:system:set \
  memcache.local --value="\OC\Memcache\Redis" --type=string
```

### PHP Configuration

Edit Nextcloud dockerfile or modify php.ini:

```ini
memory_limit = 512M
upload_max_filesize = 10G
post_max_size = 10G
max_execution_time = 3600
opcache.enable = 1
opcache.memory_consumption = 128
```

### Database Optimization

```bash
# Optimize database tables
docker-compose exec nextcloud-db mariadb -u nextcloud -p'nextcloudPassword456' nextcloud

# In MariaDB:
OPTIMIZE TABLE oc_accounts;
OPTIMIZE TABLE oc_filecache;
OPTIMIZE TABLE oc_storages;
```

### Preview Generation

Nextcloud generates image previews. Optimize:

```bash
# Settings → Admin → Preview
# Disable unnecessary preview formats
# Enable background job for preview generation

docker-compose exec -u www-data nextcloud php occ \
  preview:generate-all -vvv
```

## Backup Strategy

### Daily Backup Script

```bash
#!/bin/bash
# backup-nextcloud.sh

BACKUP_DIR="/mnt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/nextcloud_$DATE.tar.gz"

# Enable maintenance mode
docker-compose exec -u www-data nextcloud \
  php occ maintenance:mode --on

# Backup database
docker-compose exec nextcloud-db mysqldump \
  -u nextcloud -p'nextcloudPassword456' nextcloud > \
  "$BACKUP_DIR/nextcloud_db_$DATE.sql"

# Backup config and data
tar -czf "$BACKUP_FILE" \
  /opt/nextcloud/data/config \
  /mnt/nextcloud/files

# Disable maintenance mode
docker-compose exec -u www-data nextcloud \
  php occ maintenance:mode --off

# Cleanup old backups (keep 7 days)
find "$BACKUP_DIR" -name "nextcloud_*" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

Schedule with cron:

```bash
# Backup at 2 AM daily
0 2 * * * /path/to/backup-nextcloud.sh
```

### Restore from Backup

```bash
# Stop Nextcloud
docker-compose down

# Restore database
docker-compose up -d nextcloud-db
docker-compose exec nextcloud-db mariadb -u nextcloud -p'nextcloudPassword456' \
  nextcloud < /mnt/backups/nextcloud_db_20240315_020000.sql

# Restore files
tar -xzf /mnt/backups/nextcloud_20240315_020000.tar.gz -C /

# Restart all services
docker-compose up -d

# Run maintenance
docker-compose exec -u www-data nextcloud php occ maintenance:repair
```

## Security Hardening

### Enable Two-Factor Authentication

1. Settings → Security → Two-Factor Authentication
2. Enable TOTP (Time-based One-Time Password)
3. Users enable in Settings → Security

### Password Policy

Install app:

```bash
docker-compose exec -u www-data nextcloud php occ \
  app:enable password_policy
```

Configure:
1. Settings → Admin → Password Policy
2. Set minimum length (12+), require uppercase/numbers/symbols

### HTTPS Requirements

Force HTTPS in config.php:

```php
'overwriteprotocol' => 'https',
'hsts_header' => 'max-age=31536000',
```

### File Encryption

Enable app:

```bash
docker-compose exec -u www-data nextcloud php occ \
  app:enable encryption
```

Note: Impacts performance. Consider only for sensitive data.

### Firewall Rules

If exposed to internet, restrict via IP:

```nginx
# Allow only trusted IPs
geo $ip_whitelist {
    default 0;
    192.168.0.0/16 1;
    203.0.113.0/24 1;  # Your ISP
}

server {
    if ($ip_whitelist = 0) {
        return 403;
    }
}
```

## Troubleshooting

### Sync not working
```bash
# Check logs
docker-compose logs -f nextcloud | tail -50

# Verify database connection
docker-compose exec -u www-data nextcloud php occ \
  db:convert-type mysql -u nextcloud

# Reset sync tokens
docker-compose exec -u www-data nextcloud php occ \
  dav:reset-sync-token

# Restart sync client
```

### Memory limit exceeded
```bash
# Check current limit
docker-compose exec nextcloud php -r 'echo ini_get("memory_limit");'

# Increase memory limit
docker-compose exec nextcloud docker update \
  -m 4g nextcloud

# Update php.ini
```

### Large file uploads failing
```bash
# Check nginx body size limit
# Increase in nginx config: client_max_body_size 10G;

# Check Nextcloud upload size
docker-compose exec -u www-data nextcloud php occ config:system:set \
  upload_max_filesize --value="10G"
```

### Slow performance
```bash
# Enable Redis caching
# Disable preview generation for large libraries
# Check database optimization
# Monitor Docker resource limits
docker stats nextcloud
```

## Best Practices

1. **Regular Backups**: Daily backups with 7-day retention
2. **Updates**: Monthly security updates tested in staging
3. **Database**: Use PostgreSQL for large deployments (>500 users)
4. **Storage**: Separate /data on fast SSD
5. **Reverse Proxy**: Always use for remote access
6. **HTTPS**: Mandatory for any remote access
7. **2FA**: Enable for admin accounts
8. **Cron Jobs**: Use system cron, not AJAX

## Additional Resources

- [Nextcloud Documentation](https://docs.nextcloud.com)
- [Nextcloud Admin Guide](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Nextcloud Apps](https://apps.nextcloud.com)
- [r/Nextcloud](https://reddit.com/r/nextcloud)
- [Nextcloud Forum](https://help.nextcloud.com)

---

✅ **Nextcloud personal cloud storage deployed with MariaDB and Redis caching!**
