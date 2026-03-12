# 📚 Documentation Best Practices #best-practices #documentation #organization #knowledge-base

Why documentation matters and how to maintain a knowledge base for your homelab.

## Table of Contents
1. [Why Documentation Matters](#why-documentation-matters)
2. [What to Document](#what-to-document)
3. [Documentation Tools](#documentation-tools)
4. [Network Topology](#network-topology)
5. [Credential Management](#credential-management)
6. [Procedures & Runbooks](#procedures--runbooks)
7. [Change Log](#change-log)
8. [Physical Equipment](#physical-equipment)
9. [Disaster Recovery](#disaster-recovery)
10. [Keeping Docs Updated](#keeping-docs-updated)

## Why Documentation Matters

### Time Savings
```
Without Documentation:
- Forget how something is configured after 3 months
- 30 minutes debugging something previously solved
- Re-research the same problem twice
- Cannot remember port mappings

With Documentation:
- 2 minutes to find answer in docs
- 15 minutes to deploy similar service
- Consistent configurations
- Training others becomes possible
```

### Disaster Recovery
```
Scenario: Hard drive failure on ESXi host
Without documentation:
- Lost record of all VMs that were running
- Don't remember VM resource allocation
- Can't recall where backups are stored
- Hours/days to reconstruct

With documentation:
- Know exactly what was running
- Have resource allocation specs
- Backup location clearly documented
- 1-2 hours to full recovery
```

### Knowledge Transfer
```
Scenario: Have to explain setup to family member
Without documentation:
- "Um, let me show you... it's somewhere in that messy folder..."
- Can't explain the logic
- Forgotten details cause confusion

With documentation:
- Hand them the network topology
- Show step-by-step access procedures
- Explain design decisions
- Clear and professional
```

## What to Document

### Critical Documentation Checklist
```
✓ Network Topology & IP Addresses
✓ Services & Their Purposes
✓ Access Credentials (encrypted!)
✓ Installation & Setup Procedures
✓ Regular Maintenance Tasks
✓ Backup & Recovery Procedures
✓ Change Log of Major Changes
✓ Hardware Specifications
✓ Port Mappings & Firewall Rules
✓ DNS Names & Aliases
✓ Emergency Contact Information
✓ Third-party Service Details (DNS, DDNS, etc.)
```

### Example Documentation Structure
```
homelab-docs/
├── README.md                    # Overview
├── NETWORK.md                   # Network topology
├── SERVICES.md                  # Services list
├── CREDENTIALS.md.gpg           # Encrypted credentials
├── PROCEDURES/
│   ├── BACKUP.md                # Backup procedures
│   ├── RECOVERY.md              # Recovery procedures
│   ├── ADD_VM.md                # Creating new VM
│   ├── RESTART.md               # Service restart procedures
│   └── TROUBLESHOOTING.md       # Common issues & fixes
├── HARDWARE.md                  # Hardware specifications
├── CHANGES.md                   # Change log
└── EMERGENCY.md                 # Emergency procedures
```

## Documentation Tools

### Option 1: Plain Text (Markdown)
**Pros:**
- No software needed
- Version control friendly (git)
- Easy to search
- Lightweight

**Cons:**
- Limited formatting
- No built-in search interface
- Harder to link documents

**Good for:**
- Technical documentation
- Stored in git
- Team collaboration

```bash
# Example setup
git init homelab-docs
cd homelab-docs
mkdir PROCEDURES HARDWARE
echo "# Homelab Documentation" > README.md
git add .
git commit -m "Initial documentation structure"
```

### Option 2: Obsidian (Recommended for individuals)
**Pros:**
- Beautiful interface
- Excellent linking between notes
- Local storage (privacy)
- Graph visualization
- Free with optional sync

**Cons:**
- Desktop/mobile app only
- Sync is paid service
- Not ideal for team

**Installation:**
```bash
# Download from https://obsidian.md/
# Create vault in ~/homelab-vault
# Create notes with markdown
# Obsidian auto-indexes everything
```

### Option 3: Wiki.js (Best for team/sharing)
**Pros:**
- Web-based interface
- Shareable with others
- Built-in search
- Version history
- Docker deployment

**Cons:**
- Requires hosting
- More complex setup
- Database needed

**Quick setup:**
```bash
docker run -d \
  -p 3000:3000 \
  -e DB_TYPE=sqlite \
  -e DB_FILEPATH=/data/wiki.db \
  -v /path/to/data:/data \
  requarks/wiki:latest

# Access at http://localhost:3000
```

### Option 4: BookStack (Document sharing)
**Pros:**
- Professional appearance
- Organized by books/chapters
- Great for public documentation
- Docker available

**Cons:**
- More resource-heavy
- Overkill for personal homelab
- Requires more configuration

**When to use:**
- Sharing homelab documentation publicly
- Professional documentation
- Team with many docs

### Option 5: Notion
**Pros:**
- Beautiful interface
- Highly customizable
- Good for organization
- Free tier available

**Cons:**
- Cloud-based (privacy concern)
- Requires internet
- Limited offline access

**Good for:**
- Quick setup
- Non-sensitive information
- Personal use

## Network Topology

### Network Diagram
```
Document your network visually:

Tools:
- Draw.io (free, web-based)
- Lucidchart (powerful, paid)
- Miro (whiteboard-style)
- Dia (open-source desktop)

Document in markdown:
[Network Topology](./network-diagram.png)

Key info in diagram:
- VLAN networks and IPs
- Physical device connections
- Firewall placement
- Internet connection
- Device names
- Important ports/services
```

### IP Address Table
```markdown
# IP Address Reference

| IP | Hostname | VLAN | Service | Purpose | Notes |
|----|----------|------|---------|---------|-------|
| 10.1.0.1 | gateway | Mgmt | pfSense | Firewall | Primary router |
| 10.1.0.10 | esxi-1 | Mgmt | ESXi | Hypervisor | Main host |
| 10.2.0.10 | pi-hole | Prod | DNS | Primary DNS | Ad blocking |
| 10.2.0.11 | adguard | Prod | DNS | Secondary DNS | Backup DNS |
| 10.2.0.20 | plex | Prod | Plex | Media server | For clients |
| 10.3.0.40 | db-primary | DB | MySQL | Database | Main database |
| 10.4.0.50 | nas-1 | Storage | NAS | Backup storage | RAID6 |
```

## Credential Management

### Encrypted Credentials File
```bash
# Create credentials file
cat > credentials.txt <<EOF
DNS Providers:
- Pi-hole: admin / [password]
- AdGuard: admin / [password]

Database:
- MySQL root: / [password]
- MySQL app user: appuser / [password]

SSH Keys:
- Location: ~/.ssh/homelab_admin
- Passphrase: [passphrase]

VPN:
- WireGuard config: /etc/wireguard/wg0.conf

Third-party:
- DynDNS account: username / [password]
- Domain registrar: email / [password]
EOF

# Encrypt file
gpg --symmetric --cipher-algo AES256 credentials.txt
# This creates credentials.txt.gpg

# Remove plaintext
rm credentials.txt

# Later, decrypt to view
gpg --decrypt credentials.txt.gpg

# Store .gpg file safely with git
git add credentials.txt.gpg
git commit -m "Update credentials (encrypted)"
```

### Password Manager Alternative
```
Option: Use dedicated password manager
- 1Password, Bitwarden, KeePass
- Can share securely with family
- Better than plaintext files
- Easier access from multiple devices

Document this location in main docs
"See 1Password vault for credentials"
```

## Procedures & Runbooks

### Backup Procedure
```markdown
# Backup Procedure

## Daily Backup
1. SSH to backup server: `ssh backup-1`
2. Run backup script: `/opt/backup/daily.sh`
3. Verify backup completed: `ls -lah /backups/daily/`
4. Expect completion in 30 minutes
5. Check logs: `tail -f /var/log/backup.log`

## Weekly Full Backup
- Schedule: Sunday 2:00 AM
- Command: `sudo /opt/backup/full.sh`
- Duration: ~4 hours
- Verify: Check `/backups/weekly/` for latest

## Backup Verification
- Monthly restore test from backup
- Verify file integrity: `sha256sum -c checksums.txt`
- Check backup encryption: `file /backups/latest/`
- Test recovery to spare drive

## Disaster Recovery
- See RECOVERY.md for full restore procedure
```

### Adding New Service Procedure
```markdown
# Adding a New Docker Service

## Prerequisites
- Document service purpose
- Identify storage needs
- Plan resource allocation
- Choose hostname/IP

## Steps
1. Create service directory: `mkdir -p /services/myapp`
2. Create docker-compose.yml:
   ```yaml
   version: '3'
   services:
     app:
       image: myapp:latest
       ports:
         - "8080:8080"
       volumes:
         - /services/myapp/data:/data
   ```
3. Create data directory: `mkdir -p /services/myapp/data`
4. Start service: `docker-compose up -d`
5. Verify running: `docker ps`
6. Test access: `curl http://localhost:8080`
7. Add to documentation
8. Add to backup schedule if needed
9. Test restart: `docker-compose restart`

## Documentation Update
- Add to SERVICES.md
- Update network diagram if needed
- Add to PROCEDURES/BACKUP.md
- Add credentials to credentials.txt.gpg
```

## Change Log

### Track Major Changes
```markdown
# Change Log

## 2024-03-12
- Upgraded ESXi to 8.0.1
- Replaced failing HDD in NAS
- Updated Pi-hole to v5.18
- Increased VM memory limit from 32GB to 48GB
- Note: Tested backup recovery after upgrade

## 2024-03-05
- Migrated Plex to new VM
- Old Plex VM decommissioned
- Updated DNS entries for new Plex IP
- Verified all client access working

## 2024-02-28
- Added second DNS server (AdGuard)
- Configured DHCP failover
- Tested DNS failover scenario
- Updated network documentation

## 2024-02-20
- Network outage due to switch failure
- Replaced switch with managed model
- Added VLAN configuration
- Restored all services by 5 PM

## 2024-02-15
- Initial homelab setup documentation
- Network topology documented
- Backup procedures established
```

### Why Change Log Matters
```
Benefits:
- Understand what changed when something broke
- Know when features were added
- Reference for similar tasks
- Historical understanding
- Disaster recovery context
```

## Physical Equipment

### Hardware Inventory
```markdown
# Hardware Inventory

## Servers
| Device | Location | Purpose | CPU | RAM | Storage | Status |
|--------|----------|---------|-----|-----|---------|--------|
| ESXi-1 | Rack A | Main hypervisor | 2×E5-2640 | 64GB | 2×1TB SSD | Active |
| NAS-1 | Rack B | Storage | Ryzen 5 | 16GB | 4×8TB HDD | Active |
| Router | Shelf C | Firewall | Celeron | 4GB | 32GB | Active |

## Networking
| Device | Model | Location | Purpose | Status |
|--------|-------|----------|---------|--------|
| Switch | TP-Link TL-SL3428 | Rack A | Core switch | Active |
| AP | Ubiquiti 6E | Room 1 | WiFi access | Active |
| UPS | APC 1500VA | Rack A | Power backup | Active |

## Cables & Connections
- ESXi-1 eth0 → Switch port 1
- ESXi-1 eth1 → Switch port 2 (VLAN 30)
- NAS-1 eth0 → Switch port 3
- Router → Switch port 24 (uplink)

## Warranty & Support
- ESXi-1: Dell support ends 2025-06-01
- UPS: Battery replacement needed 2024-05-01
```

### Physical Labeling
```
Recommended labeling system:
- Label all cables with endpoint IDs
  Example: "ESXi-1:eth0" on both ends
- Label power cables at outlet and device
- Label servers on front and rear
- Use consistent naming (matches documentation)

Tool: Brother P-touch label maker
Cost: ~$30, highly recommended
```

## Disaster Recovery

### Recovery Procedures
```markdown
# Disaster Recovery Plan

## Scenario: Hard Drive Failure
1. Identify failed drive: Check logs and alerts
2. Power down affected system
3. Replace drive with identical model (keep spare on hand)
4. Power back on, verify boot
5. Restore from backup using standard procedure
6. Verify services operational
7. Document in change log

Time to recovery: ~30 minutes

## Scenario: Complete System Loss
1. Obtain replacement hardware (identical specs if possible)
2. Install OS using documented procedure
3. Restore from most recent full backup
4. Restore configuration files from backup
5. Verify all services running
6. Test network connectivity
7. Document recovery process

Time to recovery: ~2 hours

## Scenario: Network Outage
1. Check ISP status (can't fix ISP issues)
2. Power cycle modem (wait 2 minutes)
3. Power cycle firewall/router
4. Check all services still running
5. Verify internal network connectivity
6. If persistent: fallback to mobile hotspot
7. Update status in documentation

## Backup Recovery Test
- Monthly: Test restore from automated backup
- Restore to spare drive/VM
- Verify data integrity
- Document any issues found
- Update procedures if needed

Location of backups:
- On-site: /backups on NAS-1
- Off-site: Cloud backup (see credentials)
- External drive: In fireproof safe
```

## Keeping Docs Updated

### Version Control with Git
```bash
# Set up git repository
cd ~/homelab-docs
git init
git config user.email "you@example.com"
git config user.name "Your Name"

# Add all docs
git add .

# Commit with descriptive message
git commit -m "Initial documentation setup"

# After changes
git add SERVICES.md
git commit -m "Added new Plex service to documentation"

# View history
git log --oneline -10

# See what changed
git diff HEAD~1 SERVICES.md
```

### Update Schedule
```
- After any major change: Update immediately
- Monthly: Review and update all docs
- Quarterly: Comprehensive review
- Annually: Archive old docs, clean up

Add reminder to calendar:
- 1st of each month: Documentation review
- After service changes: Update docs
- Quarterly: Full documentation audit
```

### Make Docs Findable
```
# Create comprehensive README
cat > README.md <<EOF
# Homelab Documentation

Quick Links:
- [Network Topology](./NETWORK.md)
- [Services List](./SERVICES.md)
- [Procedures](./PROCEDURES/)
- [Hardware](./HARDWARE.md)
- [Change Log](./CHANGES.md)

Search Tips:
- Use Ctrl+F in markdown editor
- Use grep for git-stored docs
- Use Obsidian search feature
- Use Wiki.js full-text search

Emergency Contact:
- See EMERGENCY.md
EOF

git add README.md
git commit -m "Add README for better navigation"
```

### Sharing Documentation
```bash
# Share via GitHub (public)
# Avoid credentials in public repo!
git clone <repo-url>

# Share via encrypted drive
# Encrypt entire documentation directory
tar czf homelab-docs.tar.gz homelab-docs/
gpg --encrypt homelab-docs.tar.gz

# Share via password-protected wiki
# Use Wiki.js with authentication
# Set up user accounts for family members
```

## Best Practices

- Document as you build, not after
- Keep credentials encrypted and separate
- Use version control for everything
- Update documentation immediately after changes
- Make docs easily searchable
- Review documentation quarterly
- Keep backups of documentation itself
- Use consistent formatting and naming
- Include reasoning for design decisions
- Test recovery procedures regularly

---

✅ Documentation guide complete - create a knowledge base for your homelab
