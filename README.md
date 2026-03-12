# @skaisser Homelab

> Skaisser HomeLab Documentation and Scripts

[![Star](https://img.shields.io/github/stars/skaisser/homelab?style=for-the-badge&logo=github&label=Star)](https://github.com/skaisser/homelab) [![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

## What's inside

Documentation and battle-tested scripts for building and managing a professional home lab — from bare metal to containers, storage to automation.

### Infrastructure

| Area | Topics |
| ---- | ------ |
| **[Virtualization](docs/virtualization/)** | Proxmox, KVM/QEMU, VM management |
| **[Containers](docs/containers/)** | Docker, Compose, LXC |
| **[Storage](docs/storage/)** | TrueNAS, ZFS, NAS configuration |

### Services

| Area | Topics |
| ---- | ------ |
| **[Networking](docs/networking/)** | VLANs, DNS, VPN, reverse proxy |
| **[Monitoring](docs/monitoring/)** | Prometheus, Grafana, log management |
| **[Security](docs/security/)** | SSH, firewalls, access control |
| **[Automation](docs/automation/)** | Ansible, scripting, CI/CD |

### Applications

| Area | Topics |
| ---- | ------ |
| **[Media](docs/media/)** | Plex, Jellyfin, hardware transcoding |
| **[Home Automation](docs/home-automation/)** | Home Assistant, Node-RED, IoT |
| **[Self-hosted](docs/self-hosted/)** | Cloud storage, git, password managers |

### Management

| Area | Topics |
| ---- | ------ |
| **[Backup](docs/backup/)** | Strategies, cloud integration, recovery |
| **[Maintenance](docs/maintenance/)** | Updates, health monitoring, tuning |
| **[Troubleshooting](docs/troubleshooting/)** | Network, system, performance |

---

## Scripts

Ready-to-use automation scripts organized by category in [`scripts/`](scripts/).

### Media (`scripts/media/`)

| Script | What it does |
| ------ | ------------ |
| **download-organize-pipeline.sh** | Orchestrates download + sorting pipeline |
| **clean-non-media-files.sh** | Removes non-media files from directories |
| **organize-videos-with-metadata.sh** | Creates per-video folders with subtitles/artwork |
| **flatten-videos-to-root.sh** | Moves nested videos to main directory |
| **convert-bdmv-to-h264.sh** | Converts Blu-ray BDMV to H.264 MKV (GPU) |
| **convert-iso-to-mkv-gpu.sh** | Converts ISO files to MKV (GPU) |
| **audit-tmdb-naming.sh** | Finds folders missing `{tmdb-}` format |
| **audit-video-folders.sh** | Reports folders with multiple video files |
| **find-bdmv-and-iso.sh** | Discovers BDMV folders and ISO files |
| **find-cd-files.sh** | Finds CD1-CD10 split files |
| **organize-google-photos.sh** | Sorts Google Photos export by type |

### Backup (`scripts/backup/`)

| Script | What it does |
| ------ | ------------ |
| **gdrive-shared-single.sh** | Backs up shared Google Drive files |

### Migration (`scripts/migration/`)

| Script | What it does |
| ------ | ------------ |
| **rsync-parallel-move.sh** | High-performance parallel file transfers |
| **rsync-single-move.sh** | Single-process rsync with progress |
| **rsync-archive-migration.sh** | Archive data migration between storage |

### Cleanup (`scripts/cleanup/`)

| Script | What it does |
| ------ | ------------ |
| **find-and-remove-duplicates.sh** | MD5-based duplicate detection and removal |
| **remove-empty-files-and-dirs.sh** | Removes zero-byte files and empty directories |
| **remove-incomplete-downloads.sh** | Removes partial/incomplete download files |
| **remove-small-folders.sh** | Removes folders under 100MB threshold |

### Network (`scripts/network/`)

| Script | What it does |
| ------ | ------------ |
| **find-available-ip.sh** | Scans subnet to find available IPs |

---

## Getting started

### Clone

```bash
git clone https://github.com/skaisser/homelab.git
cd homelab
```

Or via SSH:

```bash
git clone git@github.com:skaisser/homelab.git
```

### Use with Obsidian

This repo works as an [Obsidian](https://obsidian.md) vault — open the folder as a vault for linked navigation, tags, and graph view.

See [OBSIDIAN_SETUP.md](OBSIDIAN_SETUP.md) for details.

---

## Skill levels

Guides are marked with difficulty levels:

- `beginner` — no prior experience needed
- `intermediate` — basic Linux knowledge required
- `advanced` — solid understanding of Linux concepts

---

## Contributing

Contributions welcome — fixes, new guides, or improved scripts.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## Resources

- [Docker Docs](https://docs.docker.com/)
- [ZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [TrueNAS Documentation](https://www.truenas.com/docs/scale/)
- [r/homelab](https://www.reddit.com/r/homelab/)

---

## License

MIT — use freely, share openly.

---

Made with care by **Shirleyson Kaisser** — [to@skaisser.dev](mailto:to@skaisser.dev)
