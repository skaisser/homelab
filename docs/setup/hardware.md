# 🖥️ Hardware Planning & Selection Guide #setup #hardware #basics #planning

Choosing the right hardware for your homelab based on your needs, budget, and long-term goals.

## Table of Contents
1. [Hardware Options](#hardware-options)
2. [CPU Considerations](#cpu-considerations)
3. [RAM Planning](#ram-planning)
4. [Storage Strategy](#storage-strategy)
5. [Networking Hardware](#networking-hardware)
6. [Power & Cooling](#power--cooling)
7. [Noise Levels](#noise-levels)
8. [Starter Builds](#starter-builds)
9. [Compatibility](#compatibility)
10. [Future Upgrades](#future-upgrades)

## Hardware Options

### Repurposed Desktop/Laptop PCs
**Pros:**
- Very affordable (often free)
- Sufficient for light workloads
- Good learning platform

**Cons:**
- Limited expansion
- Higher power consumption
- Often smaller storage capacity

**Suitable for:**
- Learning Linux
- Running single service
- Light virtualization

**Example specs:**
```
Intel i5 or equivalent
8-16GB RAM
256GB SSD + 1TB HDD
```

### Mini PCs
**Pros:**
- Compact form factor
- Reasonable power consumption
- Good balance of performance/price

**Cons:**
- Limited upgrade potential
- Fewer expandable slots
- Thermal limitations with high load

**Popular models:**
- Lenovo ThinkCentre M90q Tiny
- Beelink Pro Mini PC
- ASUS PB60
- Intel NUC

**Suitable for:**
- Small homelab (2-4 services)
- Moderate virtualization
- Docker container host

### Rack Servers
**Pros:**
- Highly scalable
- Better thermal management
- Professional components
- Dual sockets for CPUs

**Cons:**
- Expensive initially
- High power consumption
- Rack space required
- Noise/cooling requirements

**Common sources:**
- eBay (used enterprise servers)
- Dell R620, R630 series
- HP ProLiant DL360, DL380
- Supermicro systems

**Suitable for:**
- Production-grade homelab
- Multiple VMs and services
- High availability testing

### Single Board Computers (SBC)
**Pros:**
- Extremely low power
- Very affordable
- Community support

**Cons:**
- Limited performance
- Network limitations (often 100Mbps)
- Single core bottleneck often

**Popular options:**
- Raspberry Pi (4GB+ RAM version)
- Orange Pi
- Banana Pi

**Suitable for:**
- Learning and experimentation
- Lightweight services (Pi-hole, AdGuard, Home Assistant)
- Network-based tasks

## CPU Considerations

### Intel vs AMD
```
INTEL XEON (Server)
Pros: ECC memory support, reliability track record
Cons: Higher cost, older generations available used
Models: E5-2600/2700 (Sandy/Ivy Bridge), Scalable series
Power: 80-150W typical

AMD RYZEN/EPYC (Server/Desktop)
Pros: Better price, newer architecture, more cores per dollar
Cons: Fewer ECC options in consumer line
Models: Ryzen 5000 series, EPYC 7002 series
Power: 65-105W typical

INTEL CORE (Desktop)
Pros: Widely available, sufficient for homelab
Cons: No ECC support, lower core count
Models: i5-8400+, i7-9700+
Power: 65-95W typical
```

### Performance Tiers
```
CPU Selection by Need:

Single-user/Light workload:
- Intel Celeron / Pentium
- AMD Ryzen 3
- 1-2 virtual cores needed

Small homelab (5-10 VMs):
- Intel Core i5 / i7
- AMD Ryzen 5 / 7
- 4-8 cores recommended

Medium homelab (10-20 VMs):
- Intel Xeon E5 v3+
- AMD Ryzen 9
- 8-16 cores recommended

Large homelab (20+ VMs):
- Intel Xeon Scalable
- AMD EPYC
- 16+ cores, dual socket preferred
```

### Checking CPU Info
```bash
# View CPU details
cat /proc/cpuinfo | head -30

# Count cores
cat /proc/cpuinfo | grep processor | wc -l

# Check for virtualization support
grep vmx /proc/cpuinfo  # Intel
grep svm /proc/cpuinfo  # AMD

# Check for ECC support (XEON/EPYC)
grep ecc /proc/cpuinfo
```

## RAM Planning

### Memory Requirements by Use Case
```
Minimum baseline: 8GB
- Single service homelab
- Basic Docker setup
- 2-3 light VMs

Small homelab: 16GB
- 5-10 lightweight VMs
- Multiple Docker containers
- Basic Kubernetes setup

Medium homelab: 32GB
- 10-20 VMs
- Production services
- Heavy container workloads

Large homelab: 64GB+
- 20+ VMs
- High-availability setup
- Memory-intensive applications
```

### ECC vs Non-ECC RAM
```
ECC (Error-Correcting Code)
Pros: Detects and corrects memory errors
Cons: More expensive, requires ECC-capable CPU
Best for: Production systems, server workloads

Non-ECC RAM
Pros: Cheaper, works in any system
Cons: No error correction capability
Fine for: Non-critical homelabs, testing/learning
```

### Memory Calculation
```bash
# For virtualization, assume per-VM:
Lightweight VM: 1-2GB (lightweight OS + light service)
Standard VM: 2-4GB (typical application)
Heavy VM: 4-8GB (databases, heavy processing)

# Example calculation:
- Host OS: 4GB
- 3 lightweight VMs: 3 × 2GB = 6GB
- 2 standard VMs: 2 × 4GB = 8GB
- Total: 4 + 6 + 8 = 18GB (round to 32GB with headroom)

# For Docker:
- Host OS: 2-4GB
- Containers: Share OS, allocate total working set
- Containers + overhead: 8-16GB typical
```

### Speed & Type Considerations
```
DDR4 (2133-3200 MHz): Current standard
- Older systems use this
- 3200MHz is sweet spot for price/performance

DDR5 (4800MHz+): Newer systems
- Better for latest CPUs
- Higher cost, minimal improvement for homelab

Recommendation:
- Match RAM speed to motherboard support
- 3200MHz DDR4 for budget systems
- DDR5 if building new system
```

## Storage Strategy

### Storage Type Comparison
```
SSD (Solid State Drive)
Speed: 500MB/s - 7000MB/s
Cost: $0.05-0.15 per GB
Noise: Silent
Use: OS, active services, databases
Recommendation: 256GB minimum for OS

HDD (Hard Drive)
Speed: 100-200MB/s
Cost: $0.01-0.03 per GB
Noise: 30-40dB
Use: Bulk storage, backups, archives
Recommendation: Multiple drives for redundancy

NVMe (M.2 SSD)
Speed: 3500MB/s - 7000MB/s
Cost: $0.06-0.12 per GB
Noise: Silent
Use: High-performance VM storage
Recommendation: If available, excellent for VM host
```

### Storage Configuration
```
Single drive system (budget):
- 512GB SSD (OS + services)
- Add USB external for backups

Dual drive system (balanced):
- 256GB NVMe (OS + VM storage)
- 2TB HDD (bulk storage + backups)

Enterprise-style system:
- 512GB NVMe RAID 1 (OS + fast storage)
- 4 × 4TB HDD (storage pool)
- Backup drive externally

Virtual machine storage:
- Avoid single HDD for VMs
- Use SSD or NVMe for VM disks
- HDD acceptable for bulk storage

Backup strategy:
- 2× storage capacity for offline backup
- Separate physical location for disaster recovery
```

### Calculating Storage Needs
```bash
# VM storage calculation:
VM OS: 20-40GB each
VM data: Variable (databases: 10-100GB+)
Snapshots: Up to 50% of VM size

Example:
5 VMs × 30GB OS = 150GB
5 VMs × 50GB data = 250GB
Snapshots (20%): 80GB
Total VM storage needed: 480GB (plan 500GB+ usable)

# Docker storage:
Container images: 5-10GB total typical
Container data: Variable (depends on application)
Recommendation: 50GB+ for active development
```

## Networking Hardware

### Network Interface Cards (NICs)
```bash
# Check current NIC
ethtool eth0

# For homelab, consider:
- 1GbE: Sufficient for most homelabs
- 10GbE: Overkill unless storage-intensive
- Multi-port NIC: Good for VLAN separation
```

### Switches (Managed vs Unmanaged)
```
Unmanaged Switch
- Plug and play
- No configuration
- No VLAN support
- Suitable for: Small homelab, simple setup

Managed Switch (Layer 2)
- VLAN support
- Port security
- Quality of Service (QoS)
- Suitable for: Medium homelab with network segregation

Managed Switch (Layer 3)
- Routing capabilities
- VLAN routing
- Advanced features
- Suitable for: Complex networks, production-grade homelab

Recommendations:
- Budget: TP-Link LS28G (managed, affordable)
- Mid-range: Dell PowerConnect series
- Quality: Ubiquiti UniFi (managed + software control)
- Enterprise: Arista, Juniper (expensive, overkill)
```

### WiFi Access Points (Optional)
```
Built-in WiFi often insufficient for homelab services
Consider separate AP for:
- Management access
- Non-critical services
- Client devices

Recommendation:
- Ubiquiti UniFi 6E
- TP-Link EAP670
- Aruba Instant On
```

## Power & Cooling

### Power Consumption Calculation
```
Example system power:
CPU: 65W
Motherboard: 30W
RAM: 5W
SSD: 2W
HDD (4×): 4 × 8W = 32W
Network: 10W
Fans: 10W
PSU overhead (20%): ~180W × 1.2 = 216W

Total PSU needed: 300-400W
```

### PSU Selection
```
Rule of thumb: PSU capacity = peak load × 1.5

250W PSU: SBC, Mini PC
400-500W: Single drive + light VMs
700-1000W: 2 CPUs + multiple drives
1200-1500W+: Rack server setup
```

### Cooling Considerations
```
Air cooling sufficient for most homelabs:
- Standard tower coolers adequate
- Case fans for airflow
- Monitor temperatures regularly

Check temperatures:
sensors            # For CPU/motherboard
hddtemp /dev/sda  # For drives
nvidia-smi        # For GPUs if present

Ideal temperatures:
CPU: <70°C under load
HDD: <40°C
SSD: <50°C
```

### Noise Reduction
```
Typical dB levels:
- Silent: <30dB (SBC, fanless)
- Quiet: 30-40dB (good for living spaces)
- Moderate: 40-50dB (acceptable for office)
- Loud: 50+dB (server room only)

Tips:
- Use low-speed fans
- Fanless PSUs available
- HDD quieter than large case fans
- Rack equipment inherently noisier
```

## Starter Builds

### $300-400 Budget Build
```
Use Case: Learning Linux, single service, light containers
Specs:
- Refurbished Mini PC (Lenovo ThinkCentre)
- Intel i5-6500 or equivalent
- 8GB DDR4 RAM (upgradeable to 16GB)
- 256GB SSD
- Gigabit Ethernet

Cost: ~$300
Power: 15-20W average
```

### $600-800 Balanced Build
```
Use Case: 5-10 VMs, moderate services, decent Docker host
Specs:
- Used Intel Core i7 motherboard system or new budget
- 16GB DDR4 RAM (upgrade potential to 32GB)
- 256GB NVMe SSD (OS/VMs)
- 1-2TB HDD (bulk storage)
- Gigabit Ethernet

Cost: ~$700
Power: 40-60W average
```

### $1200-1500 Production-Grade Build
```
Use Case: Serious homelab, HA testing, production services
Specs:
- Used rack server (Dell R620, HP DL360) or new AM5 platform
- 32GB DDR4 ECC RAM
- 512GB NVMe SSD (OS/fast VMs) + 2TB HDD (storage)
- Dual 1GbE or single 10GbE (if server included)
- 1000W+ PSU

Cost: ~$1200-1500
Power: 80-120W average
```

### $3000+ Enterprise Build
```
Use Case: Serious production homelab, multiple hosts, storage cluster
Specs:
- 2× used rack servers (dual socket Xeon)
- 64GB+ DDR4 ECC RAM each
- 1-2TB NVMe (fast storage)
- 12TB+ HDD array (bulk storage)
- 10GbE networking
- Managed switch, backup PSU

Cost: $3000+
Power: 250-400W average
```

## Compatibility

### Motherboard/CPU Compatibility
```bash
# Check socket type before buying:
Intel: LGA1151, LGA1200, LGA1700 (newer)
AMD: AM4, AM5 (current), Socket TR4 (HEDT)

Example:
Intel i5-12400 → LGA1200 socket
AMD Ryzen 5 5600X → AM4 socket
Must match motherboard socket!
```

### RAM Compatibility
```bash
# Check RAM requirements:
Generation matching (DDR4 vs DDR5)
Speed support (motherboard usually auto-limits)
ECC vs non-ECC (must match motherboard)
Capacity support (check motherboard specs)

Example:
AM4 Ryzen motherboard typically supports:
- Up to 128GB DDR4
- 3200-5200MHz
- Both ECC and non-ECC
```

### BIOS Updates
```bash
# Important before using new CPUs:
Download BIOS from motherboard manufacturer
Check CPU support list for your motherboard revision
Update BIOS (process varies, follow manual carefully)
Verify CPU recognized after update

# Check current BIOS
dmidecode -s bios-version
```

## Future Upgrades

### Plan Your Upgrade Path
```
When selecting hardware, consider:

CPU upgrade path:
- Desktop: Consumer socket may change each generation
- Server: Same socket often supports 2-3 generations

RAM upgrade path:
- Check maximum supported capacity
- Prefer systems with multiple slots
- Plan 32GB minimum for future-proofing

Storage upgrade path:
- Multiple drive bays preferred
- At least one free slot for expansion
- External storage as fallback

Network upgrade path:
- Look for PCIe slot for NIC upgrade
- Choose managed switch with future ports
```

### Upgrade Timeline
```
Typical homelab lifecycle:

Year 1: Initial setup and learning
Year 1-2: Add services, increase RAM/storage
Year 2-3: Consider secondary host for HA
Year 3-5: Full refresh or staged replacement

Budget accordingly:
- Plan 20-30% annual upgrade budget
- Replace oldest hardware first
- Deprecate obsolete equipment responsibly
```

## Best Practices

- Start small and grow gradually
- Buy hardware with upgrade potential
- Prioritize reliability over raw performance
- Plan for cooling and power draw
- Document all hardware specifications
- Keep spare parts for critical components
- Consider used/refurbished for cost savings
- Build in 30-50% capacity headroom

---

✅ Hardware planning guide complete - choose equipment aligned with your needs and budget
