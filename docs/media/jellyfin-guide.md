# 🎥 Jellyfin: Open-Source Media Server #media #jellyfin #streaming #self-hosted #open-source

The free, open-source alternative to Plex. Jellyfin provides complete control over your media server without subscriptions, analytics tracking, or cloud requirements.

## Table of Contents
1. [Jellyfin vs Plex](#jellyfin-vs-plex)
2. [Docker Compose Deployment](#docker-compose-deployment)
3. [Initial Configuration](#initial-configuration)
4. [Library Setup](#library-setup)
5. [Hardware Transcoding](#hardware-transcoding)
6. [User Management](#user-management)
7. [Plugins and Extensions](#plugins-and-extensions)
8. [Networking and Reverse Proxy](#networking-and-reverse-proxy)
9. [Client Applications](#client-applications)
10. [Troubleshooting](#troubleshooting)
11. [Additional Resources](#additional-resources)

## Jellyfin vs Plex

| Feature | Jellyfin | Plex |
|---------|----------|------|
| Cost | Free | Free + $120/year Pass |
| Open Source | Yes | No |
| Cloud Required | No | Yes (optional) |
| License/Tracking | No tracking | Proprietary, tracks usage |
| Plugins | Community | Limited |
| UI Customization | Extensive | Limited |
| Remote Access | Via reverse proxy | Built-in |
| Hardware Transcoding | VA-API, QSV, NVENC | QSV, NVENC |

**Choose Jellyfin if**: You value privacy, want no subscription costs, prefer customization
**Choose Plex if**: You want simplest setup, need built-in remote access, prefer stability

## Docker Compose Deployment

### Basic Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    hostname: jellyfin
    ports:
      - "8096:8096"
      - "8920:8920"
      - "7359:7359/udp"
      - "1900:1900/udp"
    environment:
      - JELLYFIN_CACHE_DIR=/config/cache
      - TZ=America/New_York
    volumes:
      - /opt/jellyfin/config:/config
      - /opt/jellyfin/cache:/config/cache
      - /mnt/media/movies:/movies:ro
      - /mnt/media/tv:/tv:ro
      - /mnt/media/music:/music:ro
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

### With Hardware Transcoding (GPU)

For Intel/NVIDIA acceleration:

```yaml
devices:
  - /dev/dri:/dev/dri

environment:
  - JELLYFIN_CACHE_DIR=/config/cache
  - TZ=America/New_York
```

### Initial Setup

```bash
# Create directories
mkdir -p /opt/jellyfin/{config,cache}
sudo chown -R 1000:1000 /opt/jellyfin

# Start container
docker-compose up -d

# Access Jellyfin
# http://localhost:8096
```

## Initial Configuration

### First Run Setup

1. **Language & Metadata**:
   - Select preferred language
   - Choose metadata language

2. **Library Setup**:
   - Add media folders (we'll detail this next)
   - Configure library types

3. **User Account**:
   - Set username and password
   - Configure display name

4. **Remote Access** (optional):
   - Skip for now (configure reverse proxy later)

### Settings Navigation

```
Settings → Playback
├── Transcoding
│   ├── Transcoding temporary path: /config/cache
│   ├── Maximum concurrent transcode streams: CPU cores / 2
│   └── Enable hardware acceleration: Yes (if available)
├── FFmpeg
│   └── Configure encoder options
└── Bandwidth limits
```

## Library Setup

### Adding Libraries

1. Settings → Libraries → Add Media Library
2. Select library type (Movies, TV Shows, Music, etc.)
3. Add folder path
4. Save

### Folder Structure

Jellyfin is flexible but prefers organized structure:

```
/mnt/media/
├── movies/
│   ├── The Matrix (1999)/
│   │   └── The Matrix (1999).mkv
│   └── Inception (2010)/
│       └── Inception (2010).mkv
├── tv/
│   └── Breaking Bad/
│       ├── Season 01/
│       │   ├── Breaking Bad - s01e01 - Pilot.mkv
│       │   └── Breaking Bad - s01e02 - Cat's in the Bag.mkv
│       └── Season 02/
│           └── ...
└── music/
    └── Pink Floyd/
        └── Dark Side of the Moon/
            ├── 01 - Speak to Me.flac
            └── 02 - Breathe.flac
```

### Metadata Configuration

```bash
# Settings → Libraries → [Library] → Edit

# For Movies: Collection order, file name pattern
# Pattern: {Name} ({ProductionYear})
# Example: The Matrix (1999)

# For TV: Season/Episode format
# Pattern: {SeriesName} - s{SeasonNumber:00}e{EpisodeNumber:00}
# Example: Breaking Bad - s01e01
```

## Hardware Transcoding

### Intel Quick Sync (QSV)

Update docker-compose.yml:

```yaml
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0

environment:
  - JELLYFIN_FFMPEG=/usr/lib/jellyfin-ffmpeg/ffmpeg
```

Enable in Jellyfin:
1. Settings → Playback → Transcoding
2. Hardware acceleration: Intel Quick Sync
3. Enable hardware acceleration: Checked

### NVIDIA GPU

Install NVIDIA Container Toolkit:

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

Update docker-compose.yml:

```yaml
runtime: nvidia
environment:
  - NVIDIA_VISIBLE_DEVICES=all
  - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video_decode,video_encode
```

Configure in Jellyfin:
1. Settings → Playback → Transcoding
2. Hardware acceleration: NVENC (H.264 and HEVC)
3. Enable: Checked

### VA-API (AMD/Intel Linux)

For Linux with VAAPI support:

```yaml
devices:
  - /dev/dri:/dev/dri

environment:
  - JELLYFIN_FFMPEG=/usr/lib/jellyfin-ffmpeg/ffmpeg
```

Jellyfin settings:
1. Hardware acceleration: VA-API (H.264 and HEVC)

## User Management

### Create User

Settings → Users → Add User

```bash
# Via API:
curl -X POST http://localhost:8096/Users \
  -H "X-MediaBrowser-Token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "John",
    "Password": "SecurePassword123"
  }'
```

### User Permissions

Settings → Users → [User] → Edit

- Library access (toggle per library)
- Parental rating (PG, PG-13, R, etc.)
- Feature permissions:
  - Allow playback from multiple devices
  - Allow downloading
  - Allow subtitle downloading
  - Allow sync

### Remote Users

For accessing outside network:
1. Create user
2. Share link with reverse proxy address
3. User logs in with credentials

## Plugins and Extensions

### Official Plugins

Install via Settings → Plugins

Popular plugins:
- **Anime**: Enhanced anime metadata
- **Bookshelf**: eBook support
- **Reports**: User activity reporting
- **TheTVDB**: Enhanced TV metadata
- **OMDb**: Additional movie metadata

### Plugin Installation

```bash
# Via Settings → Plugins → Repositories
# Official: https://repo.jellyfin.org/

# Manual installation:
mkdir -p /opt/jellyfin/config/plugins/
# Copy plugin files to directory
docker-compose restart jellyfin
```

### Custom Themes

Jellyfin themes available at: https://github.com/jellyfin/jellyfin-web

Install custom theme:
```
Dashboard → Settings → Display → Theme
```

## Networking and Reverse Proxy

### Internal Network Access

Port forwarding not needed. Access via:
```
http://192.168.1.100:8096
```

### Reverse Proxy Setup (Nginx)

```nginx
server {
    listen 443 ssl http2;
    server_name jellyfin.example.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    client_max_body_size 20M;

    location / {
        proxy_pass http://jellyfin:8096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Caddy Alternative

```
jellyfin.example.com {
    reverse_proxy localhost:8096
}
```

## Client Applications

Jellyfin has official clients for:

- **Web**: http://localhost:8096 (responsive)
- **Android**: Google Play Store
- **iOS**: App Store
- **Windows**: GitHub releases
- **MacOS**: App Store
- **Linux**: Flatpak available
- **Roku**: Official channel
- **Fire TV**: Official channel
- **Kodi**: Official addon
- **Chromecast**: Via web UI

Install Android:

```bash
# Download from Play Store or GitHub
https://github.com/jellyfin/jellyfin-android/releases
```

## Troubleshooting

### Transcoding not working
```bash
# Check transcoding logs
docker-compose logs -f jellyfin | grep -i transcode

# Verify FFmpeg is available
docker-compose exec jellyfin ffmpeg -version

# Check hardware acceleration
docker-compose exec jellyfin ls -la /dev/dri/
```

### Library not refreshing
```bash
# Manual refresh via API
curl -X POST http://localhost:8096/Library/Refresh \
  -H "X-MediaBrowser-Token: YOUR_TOKEN"

# Check library paths
docker-compose exec jellyfin ls -la /movies /tv
```

### Slow playback/buffering
```bash
# Check CPU usage
docker stats jellyfin

# Reduce bitrate in playback settings
# Enable hardware transcoding
# Restart Jellyfin
docker-compose restart jellyfin
```

### Remote access not working
```bash
# Verify reverse proxy is running
docker-compose logs -f nginx

# Test connection from external IP
curl https://jellyfin.example.com

# Check DNS records
nslookup jellyfin.example.com
```

## Best Practices

1. **Organize media** before importing
2. **Use reverse proxy** with SSL/TLS
3. **Regular backups** of /config directory
4. **Monitor disk usage** for cache directory
5. **Create separate users** for household members
6. **Limit transcode streams** based on CPU
7. **Update regularly** but test in staging
8. **Monitor logs** for errors

## Additional Resources

- [Jellyfin Documentation](https://docs.jellyfin.org)
- [Jellyfin GitHub](https://github.com/jellyfin/jellyfin)
- [Community Plugin Repository](https://github.com/jellyfin/jellyfin-plugin-repository)
- [r/Jellyfin](https://reddit.com/r/jellyfin)
- [Jellyfin Forum](https://forum.jellyfin.org)
- [Jellyfin Discord](https://discord.gg/zHg6Yrnqz7)

---

✅ **Jellyfin open-source media server is running with full customization and privacy control!**
