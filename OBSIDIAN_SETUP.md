# Using @skaisser Homelab with Obsidian

This guide will help you set up the homelab documentation as an Obsidian vault for offline access and easy navigation.

## Quick Setup

1. **Install Obsidian** — download from [obsidian.md](https://obsidian.md)

2. **Clone the Repository**
   ```bash
   git clone https://github.com/skaisser/homelab.git
   ```

3. **Open in Obsidian**
   - Open Obsidian
   - Click "Open folder as vault"
   - Navigate to the cloned `homelab` folder
   - Select the folder and click "Open"

## Recommended Settings

1. **Enable Essential Plugins** (Settings > Core Plugins):
   - Page Preview
   - Tag pane
   - File explorer
   - Search
   - Backlinks
   - Graph view

2. **Configure Graph View** — open Graph View and enable:
   - Show tags
   - Group by folders
   - Show file names

3. **Safe Mode** — keep enabled (no community plugins required)

## Using the Documentation

### Navigation
- Use the File Explorer to browse documents
- Click on any `[[wiki-style]]` links to navigate between documents
- Use tags (e.g., #docker, #zfs, #truenas) to find related content

### Search
- `Ctrl/Cmd + F` — in-file search
- `Ctrl/Cmd + Shift + F` — vault-wide search

### Backlinks
Open the backlinks pane to see which documents reference the current one.

## Keeping Updated

```bash
cd path/to/homelab
git pull origin main
```

Then press `Ctrl/Cmd + R` in Obsidian to refresh.

## Mobile Access

1. Install Obsidian Mobile (iOS/Android)
2. Sync options: Git mobile apps, Obsidian Sync (paid), or third-party sync (iCloud, Dropbox)

## Tips

- Use the Graph View to visualize connections between documents
- Create your own notes in a separate folder to keep them distinct
- Use tags to organize and find related content quickly
- Star frequently accessed files for quick access
