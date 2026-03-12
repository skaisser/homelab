# 🎬 Plex Media Server Setup Guide #media #plex #streaming #self-hosted

Your personal Netflix alternative running on your hardware. Plex is the most popular media server for homelabbers—stream movies, TV shows, and music across all your devices with beautiful interfaces and powerful transcoding capabilities.

## Table of Contents
1. [Overview](#overview)
2. [Docker Compose Deployment](#docker-compose-deployment)
3. [Library Configuration](#library-configuration)
4. [Hardware Transcoding](#hardware-transcoding)
5. [Remote Access](#remote-access)
6. [Plex Pass Features](#plex-pass-features)
7. [Monitoring with Tautulli](#monitoring-with-tautulli)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Additional Resources](#additional-resources)

## Overview

Plex Media Server converts your media into a streaming platform. Key features:
- Multiple library types (Movies, TV Shows, Music, Photos, etc.)
- Automatic metadata fetching and artwork
- Remote access and sharing with friends/family
- Multiple user profiles and parental controls
- Hardware transcoding for smooth playback
- Available on nearly every device

### System Requirements
- CPU: Quad-core minimum (6+ cores for heavy transcoding)
- RAM: 2GB minimum (4GB+ recommended)
- Storage: Sufficient disk space for your media library
- Network: Stable internet for remote access

## Docker Compose Deployment

### Basic Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  plex:
    image: plexinc/pms-docker:latest
    container_name: plex
    hostname: plex
    ports:
      - "32400:32400/tcp"
      - "32400:32400/udp"
      - "32469:32469/tcp"
      - "32469:32469/udp"
      - "5353:5353/udp"
    environment:
      - PLEX_UID=1000
      - PLEX_GID=1000
      - TZ=America/New_York
      - PLEX_CLAIM=claim-XXXXXXXXX  # Get from plex.tv/claim
      - ADVERTISE_IP=http://192.168.1.100:32400/
    volumes:
      - /opt/plex/config:/config
      - /opt/plex/transcode:/transcode
      - /mnt/media/movies:/movies
      - /mnt/media/tv:/tv
      - /mnt/media/music:/music
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### Setup Instructions

1. Get a claim token:
```bash
# Visit https://www.plex.tv/claim and copy the token
# Add it to the PLEX_CLAIM environment variable
```

2. Create directories:
```bash
mkdir -p /opt/plex/config /opt/plex/transcode
mkdir -p /mnt/media/{movies,tv,music}
sudo chown -R 1000:1000 /opt/plex /mnt/media
```

3. Start Plex:
```bash
docker-compose up -d
```

4. Access Plex:
```bash
# Web interface: http://localhost:32400/web
# First-time setup will guide you through configuration
```

## Library Configuration

### Adding Libraries

1. Access Settings → Libraries → Add Library
2. Choose media type (Movie, TV Show, Music)
3. Select folder containing media
4. Configure scanning and naming

### Media Organization

Plex works best with organized folder structures:

```
/mnt/media/
├── movies/
│   ├── Action/
│   │   └── The Matrix (1999)/
│   │       └── The Matrix (1999).mkv
│   └── Comedy/
│       └── Superbad (2007)/
│           └── Superbad (2007).mkv
├── tv/
│   └── Breaking Bad/
│       ├── Season 01/
│       │   ├── Breaking Bad - S01E01 - Pilot.mkv
│       │   └── Breaking Bad - S01E02 - Cat's in the Bag.mkv
│       └── Season 02/
│           └── ...
└── music/
    └── Artist Name/
        └── Album Name/
            ├── 01 - Song Title.flac
            └── 02 - Another Song.flac
```

### Automatic Scanning

Configure in Settings → Libraries:

```bash
# Adjust scanning intervals
# Full scan: Once per day (off-peak hours recommended)
# Partial scan: When changes detected (recommended)
```

Enable automatic matching:
- Settings → Library → Automatic
- Check "Prefer local metadata" if using custom artwork

## Hardware Transcoding

Hardware transcoding reduces CPU usage significantly. Plex uses FFmpeg under the hood.

### Intel Quick Sync (QSV)

Add to docker-compose.yml:

```yaml
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0

environment:
  - NVIDIA_VISIBLE_DEVICES=all
```

Enable in Plex Settings → Transcoder:
- Transcoder temporary directory: `/transcode`
- Automatic quality preference: Enabled
- Temporary directory is valid: Checked

### NVIDIA GPU

Install nvidia-docker:

```bash
# Add Docker to your system
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

Update docker-compose.yml:

```yaml
plex:
  image: plexinc/pms-docker:latest
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video_decode,video_encode
```

Verify in Plex Settings → Transcoder:
- Transcoder → Transcoding Quality: Enable hardware acceleration

### Verify Transcoding

Monitor transcoding processes:

```bash
# Watch active transcoding
watch -n 1 'curl -s http://localhost:32400/status/sessions \
  -H "X-Plex-Token: YOUR_TOKEN" | grep -oP "TranscodeSession"'

# Check Docker stats
docker stats plex
```

## Remote Access

### Enable Remote Access

1. Settings → Remote Access
2. Click "Enable Remote Access"
3. Verify connection status (green = working)

### Manual Configuration

If automatic doesn't work:

```bash
# Port forwarding (router config):
# Forward port 32400 TCP to container

# Or use reverse proxy (better security):
# nginx/Caddy configured with proper SSL
```

### Secure Remote Access

Use Plex's built-in remote access OR set up reverse proxy:

```nginx
server {
    listen 443 ssl http2;
    server_name plex.example.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    location / {
        proxy_pass http://plex:32400;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Plex Pass Features

Plex Pass ($120/year) includes:

- **Cloud Sync**: Automatic media organization
- **Watchlist**: Save movies/shows for later
- **Collections**: Create custom collections
- **Scheduled Libraries**: Schedule media refresh
- **Playback Restrictions**: DRM and restrictions management
- **Movie trailers**: Automatically download trailers
- **DVR**: Record live TV
- **Premium extensions**: Advanced themes and customization

Enable in Settings → Account → Manage Plex Pass

## Monitoring with Tautulli

Tautulli monitors and provides analytics for your Plex server.

```yaml
# Add to docker-compose.yml
tautulli:
  image: tautulli/tautulli:latest
  container_name: tautulli
  ports:
    - "8181:8181"
  environment:
    - PLEX_URL=http://plex:32400
    - PLEX_TOKEN=YOUR_TOKEN
    - TZ=America/New_York
  volumes:
    - /opt/tautulli/config:/config
    - /opt/plex/config/Library/Logs:/logs:ro
  restart: unless-stopped
```

Get Plex Token:

```bash
# Method 1: Web interface
# Settings → Account → Shows "Account" → Look for "Token" in inspect element

# Method 2: Via API
curl http://localhost:32400 -H "X-Plex-Token: YOUR_TOKEN"
```

Access Tautulli: http://localhost:8181

## Troubleshooting

### Plex not accessible remotely
```bash
# Check network status
curl -s http://localhost:32400/identity \
  -H "X-Plex-Token: YOUR_TOKEN" | grep -oP '"clientIdentifier":"[^"]+"'

# Enable upnp/nat-pmp (Settings → Remote Access)
# Check port forwarding in Settings → Remote Access
```

### High CPU transcoding
```bash
# Check active transcode sessions
curl -s http://localhost:32400/status/sessions \
  -H "X-Plex-Token: YOUR_TOKEN" | jq '.'

# Reduce bitrate in client settings
# Enable hardware transcoding (Intel QSV/NVIDIA)
```

### Media not appearing in library
```bash
# Refresh library
curl -s -X POST http://localhost:32400/library/sections/1/refresh \
  -H "X-Plex-Token: YOUR_TOKEN"

# Check file permissions
ls -la /mnt/media/movies/

# Verify naming convention matches Plex standards
```

### Database corruption
```bash
# Backup before fixing
docker-compose exec plex cp -r /config /config.backup

# Optimize database
docker-compose exec plex sqlite3 /config/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "VACUUM;"
```

## Best Practices

1. **Media Organization**: Use consistent naming and folder structures
2. **Regular Backups**: Backup /config directory weekly
3. **Transcode Directory**: Place on fast local SSD
4. **Network**: Use wired connection for server stability
5. **Library Maintenance**: Remove duplicate entries regularly
6. **User Management**: Create separate profiles for household members
7. **Parental Controls**: Configure age restrictions per user
8. **Update Strategy**: Update Plex monthly, test in staging first

## Additional Resources

- [Plex Support](https://support.plex.tv)
- [Plex Media Server Manual](https://support.plex.tv/articles/200375666-media-server-meta-data-guide/)
- [Tautulli Documentation](https://github.com/Tautulli/Tautulli/wiki)
- [r/Plex](https://reddit.com/r/plex) Community
- [Plex Forums](https://forums.plex.tv)
- [The Plex Discord](https://discord.gg/plex)

---

✅ **Plex Media Server is now configured and monitoring transcoding in real-time!**
