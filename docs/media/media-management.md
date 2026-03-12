# 📺 Media Organization and Automation #media #sonarr #radarr #automation #organization

Automatic media management transforms chaos into organized libraries. Learn folder structures, naming conventions, and automated download workflows using Sonarr, Radarr, and Prowlarr.

## Table of Contents
1. [Media Organization Principles](#media-organization-principles)
2. [Naming Conventions](#naming-conventions)
3. [Sonarr: TV Shows](#sonarr-tv-shows)
4. [Radarr: Movies](#radarr-movies)
5. [Prowlarr: Indexer Management](#prowlarr-indexer-management)
6. [Filebot: Advanced Renaming](#filebot-advanced-renaming)
7. [Docker Compose Stack](#docker-compose-stack)
8. [Integration with Media Servers](#integration-with-media-servers)
9. [Troubleshooting](#troubleshooting)
10. [Additional Resources](#additional-resources)

## Media Organization Principles

### Folder Structure

Organize at the top level by media type, then alphabetically:

```
/mnt/media/
├── movies/
│   ├── A/
│   │   ├── Alien (1979)/
│   │   ├── Arrival (2016)/
│   │   └── Avatar (2009)/
│   ├── I/
│   │   └── Inception (2010)/
│   └── T/
│       ├── The Matrix (1999)/
│       └── Titanic (1997)/
├── tv/
│   ├── Breaking Bad/
│   ├── The Office (US)/
│   └── The Crown/
├── music/
│   └── Artist/
│       └── Album/
└── photos/
    ├── 2024/
    └── 2025/
```

### Naming Standards

**Movies:**
```
Title (Year).ext
The Matrix (1999).mkv
Inception (2010).mkv
Avatar (2009).mkv
```

**TV Shows:**
```
Show Name/Season ##/Show Name - S##E## - Episode Title.ext
Breaking Bad/Season 01/Breaking Bad - S01E01 - Pilot.mkv
Breaking Bad/Season 01/Breaking Bad - S01E02 - Cat's in the Bag.mkv
```

**Multi-file Episodes:**
```
Show Name - S##E## - Episode Title - Part1.ext
Show Name - S##E## - Episode Title - Part2.ext
```

**Music:**
```
Artist/Album/##_-_Track_Title.ext
Pink Floyd/Dark Side of the Moon/01 - Speak to Me.flac
```

## Naming Conventions

### Why Naming Matters

- **Plex/Jellyfin metadata matching**: Proper naming helps automatic matching
- **Organization**: Easy navigation and backup
- **Scriptability**: Consistent naming enables automation
- **Sharing**: Friends understand your structure

### Key Components

| Component | Example | Purpose |
|-----------|---------|---------|
| Title | The Matrix | Show name |
| Season | S01 | Season number (zero-padded) |
| Episode | E01 | Episode number (zero-padded) |
| Year | (1999) | Release year for disambiguation |
| Resolution | 1080p | Video quality (optional) |
| Source | WEB-DL | Source type (optional) |
| Codec | H.264 | Video codec (optional) |

## Sonarr: TV Shows

Sonarr automates TV show downloading, renaming, and organization.

### Docker Deployment

```yaml
sonarr:
  image: lscr.io/linuxserver/sonarr:latest
  container_name: sonarr
  ports:
    - "8989:8989"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/sonarr/config:/config
    - /mnt/media/tv:/tv
    - /mnt/downloads:/downloads
  restart: unless-stopped
```

### Initial Setup

Access: http://localhost:8989

1. **Settings → Media Management**:
   - Episode naming: `{Series Title} - s{season:00}e{episode:00} - {Episode Title}`
   - Season folder format: `Season {season}`
   - Series folder format: `{Series Title}`

2. **Settings → Download Clients**:
   - Add your download client (qBittorrent, Transmission, etc.)
   - Test connection

3. **Settings → Indexers**:
   - Configure via Prowlarr (see below)

### Adding Series

1. Click "Add Series"
2. Search for show
3. Select seasons to monitor
4. Choose quality profile
5. Start monitoring

```bash
# Sonarr adds to RSS feed and monitors for releases
# When episode airs, Sonarr searches indexers
# Downloads automatically, renames, and moves to /tv
```

## Radarr: Movies

Radarr automates movie downloading, renaming, and organization.

### Docker Deployment

```yaml
radarr:
  image: lscr.io/linuxserver/radarr:latest
  container_name: radarr
  ports:
    - "7878:7878"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/radarr/config:/config
    - /mnt/media/movies:/movies
    - /mnt/downloads:/downloads
  restart: unless-stopped
```

### Configuration

1. **Settings → Media Management**:
   - Movie folder format: `{Movie Title} ({Release Year})`
   - Movie naming: `{Movie Title} ({Release Year})`

2. **Settings → Download Clients**:
   - Add qBittorrent/Transmission

3. **Settings → Indexers**:
   - Connect Prowlarr

### Adding Movies

1. Click "Add Movie"
2. Search database
3. Select quality profile
4. Click Add

```bash
# Radarr searches immediately upon adding
# Downloads best match automatically
# Renames and places in /movies folder
```

## Prowlarr: Indexer Management

Prowlarr centralizes indexer management for Sonarr and Radarr.

### Docker Deployment

```yaml
prowlarr:
  image: lscr.io/linuxserver/prowlarr:latest
  container_name: prowlarr
  ports:
    - "9696:9696"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/prowlarr/config:/config
  restart: unless-stopped
```

### Setting Up Indexers

1. Access http://localhost:9696
2. Settings → Indexers → Add Indexer
3. Browse available (700+ supported)
4. Configure authentication if needed

Popular free indexers:
- 1337x
- The Pirate Bay
- EZTV (TV shows)
- YTS (movies)

### Connecting to Sonarr/Radarr

Settings → Apps → Add App

```yaml
- Sonarr: localhost:8989
- Radarr: localhost:7878
```

Sonarr/Radarr automatically sync indexers.

## Filebot: Advanced Renaming

Filebot provides scripting for complex renaming scenarios.

### Docker Deployment

```yaml
filebot:
  image: jlesage/filebot:latest
  container_name: filebot
  ports:
    - "5800:5800
  volumes:
    - /mnt/media:/media
    - /mnt/downloads:/input
  restart: unless-stopped
```

### Basic Rename Script

```bash
filebot -rename /mnt/downloads -non-strict \
  --format '/mnt/media/tv/{n}/Season {s}/{n} - s{s:00}e{e:00} - {t}'

filebot -rename /mnt/downloads -non-strict \
  --format '/mnt/media/movies/{n} ({y})'
```

### Via CLI

```bash
# TV Shows
filebot -rename /mnt/downloads --format \
  '/mnt/media/tv/{n}/Season {s}/{n} - s{s:00}e{e:00}' \
  --db tvdb

# Movies
filebot -rename /mnt/downloads --format \
  '/mnt/media/movies/{n} ({y})' \
  --db imdb
```

## Docker Compose Stack

Complete *arr stack with download client:

```yaml
version: '3.8'
services:
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    ports:
      - "9696:9696"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /opt/prowlarr/config:/config
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    ports:
      - "8989:8989"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /opt/sonarr/config:/config
      - /mnt/media/tv:/tv
      - /mnt/downloads:/downloads
    depends_on:
      - prowlarr
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    ports:
      - "7878:7878"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /opt/radarr/config:/config
      - /mnt/media/movies:/movies
      - /mnt/downloads:/downloads
    depends_on:
      - prowlarr
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    ports:
      - "6881:6881"
      - "6881:6881/udp"
      - "8080:8080"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - WEBUI_PORT=8080
    volumes:
      - /opt/qbittorrent/config:/config
      - /mnt/downloads:/downloads
    restart: unless-stopped

networks:
  default:
    name: homelab
    external: true
```

## Integration with Media Servers

### Plex Integration

1. In Sonarr/Radarr: Settings → Connect
2. Add notification for Plex
3. Server: `http://plex:32400`
4. Token: Your Plex token
5. Automatic library refresh on download

### Jellyfin Integration

1. In Sonarr/Radarr: Settings → Connect
2. Add Jellyfin webhook
3. URL: `http://jellyfin:8096/Notifications/Jellyfin`
4. Automatic library refresh

### Download Client Setup

**qBittorrent**:
1. Settings → Download Clients
2. Type: qBittorrent
3. Host: qbittorrent
4. Port: 8080
5. Test connection

## Troubleshooting

### Indexers not working
```bash
# Check Prowlarr logs
docker-compose logs -f prowlarr

# Verify API key in Sonarr/Radarr
# Settings → Apps → Test connection
```

### Files not renaming correctly
```bash
# Check file permissions
ls -la /mnt/downloads/

# Verify naming format matches
# Test with filebot first

# Check logs in Sonarr/Radarr
```

### Download not starting
```bash
# Verify download client connection
# Test in qBittorrent: Add → Paste torrent

# Check disk space
df -h /mnt/downloads
```

### Metadata not matching
```bash
# Manual search in Sonarr/Radarr
# Use Edit → Correct metadata
# Refresh metadata: Settings → Library → Refresh
```

## Best Practices

1. **Monitor disk space**: Set download folder limits
2. **Quality profiles**: Balance quality vs file size
3. **Separate profiles**: Different settings for movies/TV
4. **Regular backups**: Backup config directories
5. **Test indexers**: Verify functionality regularly
6. **Folder permissions**: Ensure docker user can write
7. **Cleanup old files**: Schedule monthly purges

## Additional Resources

- [Sonarr Documentation](https://wiki.servarr.com/sonarr)
- [Radarr Documentation](https://wiki.servarr.com/radarr)
- [Prowlarr Documentation](https://wiki.servarr.com/prowlarr)
- [Filebot Guide](https://www.filebot.net/forums/viewtopic.php?t=215)
- [r/Sonarr](https://reddit.com/r/sonarr)

---

✅ **Media automation stack deployed—TV shows and movies organizing themselves!**
