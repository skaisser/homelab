# 🌐 Network Planning & Architecture Guide #setup #networking #vlans #planning #architecture

Design a scalable, organized network foundation for your homelab that supports growth and security.

## Table of Contents
1. [Network Topology](#network-topology)
2. [IP Addressing Scheme](#ip-addressing-scheme)
3. [VLAN Planning](#vlan-planning)
4. [Subnet Design](#subnet-design)
5. [DNS Strategy](#dns-strategy)
6. [DHCP Configuration](#dhcp-configuration)
7. [Firewall Placement](#firewall-placement)
8. [VPN Access](#vpn-access)
9. [Network Diagram](#network-diagram)
10. [Growth Planning](#growth-planning)

## Network Topology

### Simple Topology (Starter)
```
                Internet (ISP)
                     |
                   Modem
                     |
          Home Router (WiFi + Ethernet)
              /        |        \
        Desktop    Homelab    Laptop
                      |
                  Services
```

**Best for:**
- Learning setup
- Minimal services
- Limited budget

**Drawbacks:**
- No network segmentation
- Limited VLAN support
- Shared bandwidth

### Tiered Topology (Recommended)
```
                Internet
                   |
           ISP Modem/Router
                   |
          Managed Switch (VLAN capable)
          /        |          \
    Management  Production  Guest
      Network    Network    Network
        |          |          |
      VPN      Homelab    Client
     Server    Services    Devices
```

**Best for:**
- Most homelabs
- Multiple services
- Network segmentation

**Advantages:**
- VLAN isolation
- Better organization
- Security boundaries

### Complex Topology (Advanced)
```
                Internet
                   |
         Firewall/Router (pfsense/OPNsense)
              /          |          \
         WAN        Managed       WiFi
                    Switch        APs
              /      |    |    \
      Management  Work  Prod  Guest
      IoT Service  Dev  Storage
      VLANs                     |
              |                 |
      Homelab cluster   Client Devices
      HA/Load Balancer
```

**Best for:**
- Production-grade homelab
- High availability
- Complex security requirements

**Advantages:**
- Full control
- Advanced routing
- Multiple edge cases

## IP Addressing Scheme

### RFC1918 Private Ranges
```
Class A:  10.0.0.0/8         (10.0.0.0 - 10.255.255.255)
Class B:  172.16.0.0/12      (172.16.0.0 - 172.31.255.255)
Class C:  192.168.0.0/16     (192.168.0.0 - 192.168.255.255)

For homelab, use one consistently:
10.0.0.0/8:      Largest, suitable for growth
172.16.0.0/12:   Medium, rarely causes conflicts
192.168.0.0/16:  Common (often used by ISP), risk of conflicts
```

### Subnet Allocation Strategy
```
10.0.0.0/8 breakdown for homelab:

Management VLAN:    10.1.0.0/24   (Router, switches, APs)
                    10.1.0.1  - Router
                    10.1.0.2-10 - Switches, APs
                    10.1.0.100-110 - DHCP pool

Production VLAN:    10.2.0.0/24   (Homelab services)
                    10.2.0.1  - VLAN gateway
                    10.2.0.2-100 - Static IPs (servers)
                    10.2.0.200-250 - DHCP pool

Database VLAN:      10.3.0.0/24   (Database servers)
                    10.3.0.1  - VLAN gateway
                    10.3.0.2-50 - Database servers (static)

Storage VLAN:       10.4.0.0/24   (NAS, backup)
                    10.4.0.1  - VLAN gateway
                    10.4.0.2-50 - Storage servers (static)

Guest VLAN:         10.5.0.0/24   (Guest/client devices)
                    10.5.0.1  - VLAN gateway
                    10.5.0.100-250 - DHCP pool

IoT VLAN:           10.6.0.0/24   (Smart home devices)
                    10.6.0.1  - VLAN gateway
                    10.6.0.100-250 - DHCP pool
```

### IP Assignment Best Practices
```bash
# Static IPs for services:
10.2.0.10 - Primary DNS (Pi-hole, AdGuard)
10.2.0.11 - Secondary DNS
10.2.0.20 - Homelab Master/Controller
10.2.0.21-30 - Additional hypervisors
10.2.0.40 - Primary database
10.2.0.41 - Secondary database
10.2.0.50 - Backup server

# DHCP ranges (never overlap with static):
10.2.0.200-250 for dynamic assignment

# Documentation
Create spreadsheet:
IP | Hostname | VLAN | Purpose | Notes
10.2.0.10 | pi-hole | Prod | DNS | Primary
10.2.0.20 | esxi-1 | Prod | Hypervisor | Main
...
```

## VLAN Planning

### VLAN Structure Example
```
VLAN ID | Name        | Subnet        | Purpose
--------|-------------|---------------|---------------------------
1       | Management  | 10.1.0.0/24   | Network infrastructure
10      | Production  | 10.2.0.0/24   | Homelab services
20      | Database    | 10.3.0.0/24   | Database servers
30      | Storage     | 10.4.0.0/24   | NAS, backup systems
40      | Guest       | 10.5.0.0/24   | Guest/client devices
50      | IoT         | 10.6.0.0/24   | Smart home devices
```

### Networking Hardware Configuration
```bash
# Example Ubiquiti UniFi managed switch setup:
Port 1-8:   Access ports (VLAN 10 - Production)
Port 9-16:  Access ports (VLAN 40 - Guest)
Port 24:    Trunk to firewall (all VLANs)
Port 48:    Uplink to core switch

# TP-Link managed switch example:
VLAN 1 (management): Ports 1-2, 24
VLAN 10 (production): Ports 3-10, 24
VLAN 40 (guest): Ports 11-16, 24
```

### Firewall Rules Between VLANs
```
Production → Management: Block (no VLAN reach-back)
Guest → Production: Block (no access to services)
Production → Storage: Allow (NFS/SMB for backups)
Management → All: Allow (for management tasks)
IoT → Guest: Block (isolate from untrusted)
IoT → Production: Block (isolate from critical)
```

## Subnet Design

### Subnet Sizing for Growth
```
/24 subnet = 256 addresses (254 usable)
Perfect for small VLANs (up to 100 devices)

/23 subnet = 512 addresses
Good for medium VLANs (100-250 devices)

/22 subnet = 1024 addresses
For large VLANs (250-500 devices)

For homelab, start with /24 per VLAN
```

### Subnet Calculation
```bash
# Check subnet info
ipcalc 10.2.0.0/24

Output should show:
Network:       10.2.0.0/24
Netmask:       255.255.255.0
Broadcast:     10.2.0.255
Min Host:      10.2.0.1
Max Host:      10.2.0.254
Hosts:         254

# For sizing:
/24 = 256 total (254 usable)
/25 = 128 total (126 usable)
/26 = 64 total (62 usable)
/27 = 32 total (30 usable)
/28 = 16 total (14 usable)
```

## DNS Strategy

### DNS Architecture
```
Recommended setup for homelab:

Option 1: Single DNS
- Pi-hole or AdGuard Home on hypervisor
- Single point of failure
- Simple to manage
- Good for learning

Option 2: Dual DNS (Recommended)
- Primary: Pi-hole (10.2.0.10)
- Secondary: AdGuard Home (10.2.0.11)
- Redundancy for DNS failure
- Load balancing capable

Option 3: Internal DNS Server
- ISC BIND or dnsmasq
- Full control
- Complex but powerful
- For advanced users
```

### DNS Configuration
```bash
# Configure resolver in firewall to point clients:
Primary DNS: 10.2.0.10 (Pi-hole)
Secondary DNS: 10.2.0.11 (AdGuard)

# In DHCP config:
Option 6: 10.2.0.10, 10.2.0.11

# Local domain for homelab:
Domain: homelab.local
Examples:
- esxi-1.homelab.local → 10.2.0.20
- database.homelab.local → 10.3.0.40
- backup.homelab.local → 10.4.0.50

# Add to Pi-hole local DNS:
esxi-1.homelab.local 10.2.0.20
database.homelab.local 10.3.0.40
storage.homelab.local 10.4.0.50
```

## DHCP Configuration

### DHCP Server Setup
```bash
# Option 1: Router DHCP
- Built into most routers
- Easy setup
- Limited customization
- Good for simple setups

# Option 2: Dedicated DHCP (isc-dhcp-server)
sudo apt-get install isc-dhcp-server

# Edit config
sudo nano /etc/dhcp/dhcpd.conf

# Example configuration:
subnet 10.2.0.0 netmask 255.255.255.0 {
  option routers 10.2.0.1;
  option domain-name-servers 10.2.0.10, 10.2.0.11;
  option domain-name "homelab.local";
  range 10.2.0.200 10.2.0.250;
  default-lease-time 3600;
  max-lease-time 7200;
}

# Start service
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server
```

### DHCP Best Practices
```bash
# Don't use DHCP for servers:
- Hypervisors: Static IP
- Database servers: Static IP
- Storage: Static IP
- DNS servers: Static IP

# Use DHCP for:
- Client devices
- Temporary devices
- Guest network
- Development machines

# Exclude ranges:
Reserve some IPs even if not in DHCP range
Example: 10.2.0.1-100 (for static assignment)
```

## Firewall Placement

### Firewall Device Options
```
Option 1: Router built-in firewall
- Simple, included
- Limited control
- Good starting point

Option 2: pfSense/OPNsense box
- Flexible, open-source
- Full control
- Moderate complexity
- Good for homelabs

Option 3: Separate firewall device
- Enterprise control
- Complex setup
- Suitable for advanced

Recommendation: pfSense/OPNsense as "edge" router
```

### Basic Firewall Rules
```
# Inbound (from internet)
- Block all by default
- Allow SSH from trusted IPs only
- Allow HTTP/HTTPS if needed
- Allow VPN connections

# Between VLANs
- Default: Block all
- Explicit allow rules only
- Example: Production → Storage (NFS/SMB)

# Outbound
- Allow all by default (from managed network)
- Block dangerous protocols
- Log unusual traffic
```

## VPN Access

### Remote Access Setup
```
Option 1: OpenVPN
- Client-based
- Good security
- Cross-platform
- Setup:
  - Server on gateway
  - Client on remote machine
  - Push routes to homelab network

Option 2: WireGuard
- Faster, simpler
- Modern protocol
- Increasingly popular
- Lightweight

Option 3: Tailscale
- Simplest setup
- Magic DNS
- Cloud-managed
- Zero trust network

Recommendation: WireGuard for best balance
```

### VPN Configuration Example
```bash
# WireGuard setup on pfSense:
1. Install WireGuard package
2. Generate keys for server
3. Create server interface (10.9.0.0/24)
4. Add firewall rules allowing VPN traffic
5. Create client configs
6. Share to clients

# Result:
- VPN clients get IP in 10.9.0.0/24
- Can reach all homelab networks
- Encrypted tunnel through WAN
```

## Network Diagram

### Example Network Map
```
                     ISP Internet
                          |
                      [Modem]
                          |
              Firewall (pfSense/OPNsense)
              Gateway: 10.1.0.1
                      /        \
          WAN (0.0.0.0)      Managed Switch
                                  |
              /-------+-------+-------+-------\
          VLAN10  VLAN20   VLAN30   VLAN40   VLAN50
          (Prod)  (DB)    (Storage) (Guest)  (IoT)
          10.2.x  10.3.x   10.4.x  10.5.x   10.6.x
            |       |        |       |        |
          [ESXi]  [DB]     [NAS]  [WiFi]   [Devices]
          [K8s]   [Redis]  [Backup] [Laptop]
          [DNS]
```

### Document Your Network
```bash
# Create network documentation:
1. Network topology diagram (draw.io, Lucidchart)
2. IP address table (spreadsheet)
3. VLAN configuration (table)
4. Firewall rules (document)
5. DNS configuration (notes)
6. VPN setup (secure backup)

# Version control your configs:
git init /etc/network-config
git add dhcp.conf firewall-rules.txt
git commit -m "Initial network setup"
```

## Growth Planning

### Expanding Your Network
```
Phase 1: Starter (0-3 months)
- Single subnet (10.2.0.0/24)
- Unmanaged or simple switch
- Basic router firewall
- 5-10 devices

Phase 2: Growth (3-12 months)
- 2-3 VLANs
- Managed switch with VLAN support
- Pi-hole DNS
- 20-30 devices

Phase 3: Advanced (1-2 years)
- 5+ VLANs
- Dedicated firewall (pfSense)
- Dual DNS
- 50+ devices
- Redundancy considerations

Phase 4: Enterprise-grade (2+ years)
- Full network segmentation
- HA firewall
- Clustered storage
- 100+ devices
- Multiple sites
```

### Capacity Planning
```
Network bandwidth needs:
- Learning: 100Mbps sufficient
- Production: 1Gbps between services
- High-availability: Multiple 1Gbps links

Storage networking:
- 1GbE: Max ~110MB/s throughput
- 10GbE: Max ~1200MB/s throughput
- For homelab, 1GbE usually sufficient

Number of devices per VLAN:
- Small homelab: 20-30 devices per VLAN
- Medium homelab: 50-100 devices per VLAN
- Large homelab: 100+ devices, consider subnet splitting
```

## Best Practices

- Document everything as you build
- Use consistent naming conventions
- Reserve IPs in blocks, not scattered
- Plan for at least 2x current size
- Separate concerns with VLANs
- Default-deny firewall approach
- Regular network diagram updates
- Backup network configurations
- Test network changes in off-hours
- Monitor network for unauthorized devices

---

✅ Network planning guide complete - design a scalable foundation for growth
