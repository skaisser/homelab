# 🐙 Gitea: Self-Hosted Git Server #self-hosted #gitea #git #devops

Lightweight GitHub alternative for teams. Gitea provides repository hosting, collaboration, and CI/CD integration on your hardware.

## Table of Contents
1. [Why Self-Host Git](#why-self-host-git)
2. [Gitea Overview](#gitea-overview)
3. [Docker Compose Deployment](#docker-compose-deployment)
4. [Initial Setup](#initial-setup)
5. [Repository Management](#repository-management)
6. [SSH Key Configuration](#ssh-key-configuration)
7. [Gitea Actions (CI/CD)](#gitea-actions-cicd)
8. [Backup and Restore](#backup-and-restore)
9. [Webhook Configuration](#webhook-configuration)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)
12. [Additional Resources](#additional-resources)

## Why Self-Host Git

### Advantages

- **Unlimited repositories**: No storage limits
- **Private by default**: Full control over visibility
- **No vendor lock-in**: Data ownership
- **Compliance**: Meet internal security requirements
- **Cost**: One-time hardware cost vs GitHub subscription
- **Custom workflows**: Extend with plugins

### Comparison

| Feature | Gitea | GitHub | GitLab CE |
|---------|-------|--------|-----------|
| Cost | Free | $4-21/month | Free |
| Self-hosted | Yes | No | Yes |
| Private repos | Unlimited | Unlimited | Unlimited |
| Actions/CI | Basic | Yes | Yes |
| Users | Unlimited | Unlimited | Unlimited |
| Setup time | 15 min | N/A | 30+ min |

## Gitea Overview

Gitea is a lightweight Git hosting written in Go. Features:

- **Repository hosting**: Public and private repos
- **User management**: Teams and organization support
- **Code review**: Pull requests with discussions
- **Issues**: Bug tracking and project management
- **Actions**: GitHub-compatible CI/CD
- **Webhooks**: Integration with external services
- **Migrations**: Import from GitHub/GitLab

Requirements:
- 2GB RAM minimum
- PostgreSQL or SQLite database
- 1GB+ storage for repositories

## Docker Compose Deployment

### Minimal Setup (SQLite)

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    hostname: gitea
    ports:
      - "3000:3000"
      - "2222:22"
    environment:
      - ROOT_URL=https://git.example.com/
      - SSH_DOMAIN=git.example.com
      - SSH_PORT=22
      - DB_TYPE=sqlite3
      - INSTALL_LOCK=true
      - SECRET_KEY=GenerateSecretKeyHere
      - INTERNAL_TOKEN=GenerateTokenHere
    volumes:
      - /opt/gitea/data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### Production Setup (PostgreSQL)

For multiple users and better performance:

```yaml
version: '3.8'
services:
  gitea-db:
    image: postgres:15-alpine
    container_name: gitea-db
    environment:
      - POSTGRES_DB=gitea
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD=secureDbPassword456
    volumes:
      - /opt/gitea/db:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - homelab

  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    hostname: gitea
    depends_on:
      - gitea-db
    ports:
      - "3000:3000"
      - "2222:22"
    environment:
      - ROOT_URL=https://git.example.com/
      - SSH_DOMAIN=git.example.com
      - SSH_PORT=22
      - DB_TYPE=postgres
      - DB_HOST=gitea-db:5432
      - DB_NAME=gitea
      - DB_USER=gitea
      - DB_PASSWD=secureDbPassword456
      - INSTALL_LOCK=true
      - SECRET_KEY=GenerateSecretKeyHere
      - INTERNAL_TOKEN=GenerateTokenHere
    volumes:
      - /opt/gitea/data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### Setup Instructions

Generate secret keys:

```bash
# Generate SECRET_KEY
openssl rand -base64 32

# Generate INTERNAL_TOKEN
openssl rand -base64 32
```

Create directories:

```bash
mkdir -p /opt/gitea/{data,db}
sudo chown -R 1000:1000 /opt/gitea
```

Start Gitea:

```bash
docker-compose up -d

# Wait for initialization
sleep 30

# Access web interface
# http://localhost:3000
```

## Initial Setup

### First-Run Installation

1. **Database Configuration**: Already pre-configured via environment
2. **General Settings**:
   - Site name: "My Gitea"
   - Repository root path: `/data/git/repositories`
   - SSH server domain: `git.example.com`
   - SSH port: `22`

3. **Admin Account**:
   - Username: `admin`
   - Email: `admin@example.com`
   - Password: Create strong password

4. **Optional Settings**:
   - Allow user registration: Toggle as needed
   - SMTP for notifications: Configure if needed
   - Disable download archives: Optional

### Post-Installation Configuration

Access: http://localhost:3000/admin

**Site Administration:**

1. Settings → System Settings
   - Run mode: Production
   - Log level: Info
   - Offline mode: Unchecked (for now)

2. Settings → Mailer (optional):
   - Enable mailer for notifications
   - Configure SMTP server

3. Settings → Repository:
   - Auto-watch on PR: Enabled
   - Default repository permission: Read

## Repository Management

### Create Repository

1. Click "+" → New Repository
2. Enter repository name
3. Initialize with README: Optional
4. License: Optional
5. Click "Create Repository"

### Clone Repository

```bash
# SSH (recommended)
git clone ssh://git@git.example.com:22/username/repo-name.git

# HTTPS
git clone https://git.example.com/username/repo-name.git
```

### Import Repository

Migrate from GitHub/GitLab:

1. Click "+" → Migrate Repository
2. Paste GitHub/GitLab URL
3. Select authorization method
4. Choose visibility (public/private)
5. Click "Migrate Repository"

```bash
# Or import via command line
git clone --mirror https://github.com/user/repo.git
cd repo.git
git push --mirror ssh://git@git.example.com:22/user/repo.git
```

### Repository Settings

Access: Repository → Settings

- **General**: Name, description, visibility
- **Collaborators**: Add team members
- **Branches**: Default branch, protection rules
- **Webhooks**: Configure integrations
- **Deploy Keys**: Add read-only SSH keys

## SSH Key Configuration

### Generate SSH Key (Client)

```bash
# Generate key pair
ssh-keygen -t ed25519 -C "email@example.com"
# Or: ssh-keygen -t rsa -b 4096 -C "email@example.com"

# Output: ~/.ssh/id_ed25519 (private) and ~/.ssh/id_ed25519.pub (public)

# Display public key
cat ~/.ssh/id_ed25519.pub
```

### Add Public Key to Gitea

1. Login to Gitea
2. Settings → SSH/GPG Keys
3. Click "Add Key"
4. Paste public key content (entire ~/.ssh/id_ed25519.pub)
5. Give it a title (e.g., "MacBook")
6. Click "Add Key"

### Configure SSH Config (Optional)

Create `~/.ssh/config`:

```
Host git.example.com
    HostName git.example.com
    Port 22
    User git
    IdentityFile ~/.ssh/id_ed25519
```

Then clone with simplified command:

```bash
git clone git.example.com:username/repo-name.git
```

### Test SSH Connection

```bash
ssh -T git@git.example.com

# Expected output:
# Hi username! You've successfully authenticated, but Gitea does not provide shell access.
```

## Gitea Actions (CI/CD)

Gitea Actions provides GitHub-compatible CI/CD workflows.

### Enable Actions

1. Site Administration → Runners
2. Click "Create Runner Token"
3. Copy token and save

### Create Workflow File

Create `.gitea/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build
```

### Register Runner

Install Gitea Runner:

```bash
# Download latest release
wget https://dl.gitea.com/act_runner/0.2.6/act_runner-0.2.6-linux-amd64

# Make executable
chmod +x act_runner-0.2.6-linux-amd64

# Register runner
./act_runner-0.2.6-linux-amd64 register \
  --instance https://git.example.com \
  --token YOUR_TOKEN

# Run runner
./act_runner-0.2.6-linux-amd64 daemon
```

Or via Docker:

```bash
docker run -d \
  --name gitea-runner \
  -e GITEA_INSTANCE_URL=https://git.example.com \
  -e GITEA_RUNNER_REGISTRATION_TOKEN=YOUR_TOKEN \
  gitea/act_runner:latest
```

## Backup and Restore

### Complete Backup

```bash
#!/bin/bash
# backup-gitea.sh

BACKUP_DIR="/mnt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/gitea_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

# Enable maintenance mode
docker-compose exec gitea gitea admin create-user --admin \
  --username admin --password tempPassword --email admin@example.com 2>/dev/null || true

# Backup data directory
docker-compose exec gitea tar -czf - -C /data . > "$BACKUP_FILE"

# Backup database (PostgreSQL)
docker-compose exec gitea-db pg_dump -U gitea gitea > \
  "$BACKUP_DIR/gitea_db_$DATE.sql"

# Cleanup old backups (keep 14 days)
find "$BACKUP_DIR" -name "gitea_*" -mtime +14 -delete

echo "Backup completed: $BACKUP_FILE"
```

Schedule cron:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup-gitea.sh
```

### Restore from Backup

```bash
# Stop Gitea
docker-compose down

# Restore data
cd /opt/gitea/data
tar -xzf /mnt/backups/gitea_YYYYMMDD_HHMMSS.tar.gz

# Restore database
docker-compose up -d gitea-db
docker-compose exec gitea-db psql -U gitea gitea < \
  /mnt/backups/gitea_db_YYYYMMDD_HHMMSS.sql

# Start Gitea
docker-compose up -d

# Verify
docker-compose logs -f gitea
```

## Webhook Configuration

### Create Webhook

1. Repository → Settings → Webhooks
2. Click "Add Webhook"
3. Select webhook type:
   - **Gitea**: Gitea webhooks
   - **Slack**: Send to Slack
   - **Discord**: Send to Discord
   - **Dingtalk**: DingTalk notifications
   - **Feishu**: Feishu/Lark notifications

### GitHub-Compatible Hook

Example for external CI/CD:

```
Payload URL: https://ci.example.com/hooks/gitea
Content Type: application/json
Events:
  - Push
  - Pull Request
Secret: Optional secret token
```

### Test Webhook

1. Click "Test Delivery"
2. Check external service logs
3. Verify payload received correctly

## Troubleshooting

### Can't clone via SSH

```bash
# Verify SSH port forwarding
ssh -p 2222 git@localhost

# Check Gitea logs
docker-compose logs gitea | grep -i ssh

# Verify public key added to account
docker-compose exec gitea cat /data/ssh/authorized_keys
```

### Repository not found error

```bash
# Check repository path
docker-compose exec gitea ls -la /data/git/repositories/

# Verify repository ownership
docker-compose exec gitea chown -R git:git /data/git/repositories/

# Restart Gitea
docker-compose restart gitea
```

### Database connection error

```bash
# Check database status
docker-compose logs gitea-db

# Verify credentials
docker-compose exec gitea-db psql -U gitea -d gitea -c "SELECT 1;"

# Restart database
docker-compose restart gitea-db gitea
```

### Actions not triggering

```bash
# Verify runner registered
docker-compose exec gitea gitea admin actions register-runner

# Check runner status
docker-compose logs gitea-runner | grep -i status

# Manually trigger workflow
# Push to repository with .gitea/workflows files
```

## Best Practices

1. **Backups**: Daily automated backups with 14-day retention
2. **SSH Keys**: Use Ed25519 (better than RSA)
3. **Webhooks**: Secure with secret tokens
4. **Access Control**: Use teams for permission management
5. **Repository Protection**: Require PR reviews before merge
6. **Updates**: Monthly updates, test in staging
7. **Monitoring**: Watch storage usage growth
8. **Cleanup**: Archive old repositories after 1 year

## Additional Resources

- [Gitea Documentation](https://docs.gitea.io)
- [Gitea GitHub Repository](https://github.com/go-gitea/gitea)
- [Gitea Docker Image](https://hub.docker.com/r/gitea/gitea)
- [r/Gitea](https://reddit.com/r/gitea)
- [Gitea Discussions](https://github.com/go-gitea/gitea/discussions)

---

✅ **Gitea Git server deployed with PostgreSQL and webhook support!**
