# 📊 Resource Management & Capacity Planning #best-practices #resources #planning #capacity

Managing CPU, memory, storage, and power resources effectively as your homelab grows.

## Table of Contents
1. [Resource Planning Philosophy](#resource-planning-philosophy)
2. [CPU Allocation](#cpu-allocation)
3. [Memory Management](#memory-management)
4. [Storage Capacity Planning](#storage-capacity-planning)
5. [Power Management](#power-management)
6. [Cost Tracking](#cost-tracking)
7. [Monitoring Resource Trends](#monitoring-resource-trends)
8. [Knowing When to Upgrade](#knowing-when-to-upgrade)
9. [Rightsizing VMs & Containers](#rightsizing-vms--containers)
10. [Growth Scaling](#growth-scaling)

## Resource Planning Philosophy

### Headroom is Essential
```
Don't utilize 100% of resources:
- 90% CPU utilization = no room for spikes
- 95% memory = risk of OOM killer
- 100% disk space = no temp file room

Safe allocation levels:
- CPU: 60-70% under normal load
- Memory: 70-80% under normal load
- Disk: 70-80% capacity
- Bandwidth: 60% peak capacity

Example:
- Physical CPU cores: 16
- Safe allocate to VMs: 16 × 0.7 = 11 cores
- Leave 5 cores for host OS and overhead
```

### Right-Sizing Approach
```
1. Start conservative
   VM: 2 cores, 2GB RAM, 50GB disk

2. Monitor actual usage
   htop, top, vmstat for weeks

3. Right-size based on data
   Increase if consistently > 70%
   Decrease if < 30% (frees resources)

4. Repeat quarterly
   Track trends, plan upgrades
```

## CPU Allocation

### Understanding CPU Units
```bash
# Physical CPU: Actual cores on motherboard
cat /proc/cpuinfo | grep processor | wc -l
# Result: 16 physical cores

# Logical CPU: Cores visible to OS
nproc
# Result: 32 (hyperthreading doubles this)

# vCPU: Virtual cores allocated to VM
# Each vCPU does NOT equal 1 logical core
# 2 vCPUs ≈ 0.5-1 logical core when not busy
# Can over-allocate, but causes contention
```

### CPU Over-Allocation
```
Physical: 16 cores
Hyperthread: 32 logical
Over-allocation ratio: Can assign 50+ vCPUs total

But:
- 50 vCPUs competing for 16 physical cores
- Causes context switching overhead
- Performance degrades

Better approach:
- Total vCPUs = Physical cores × 2
- Example: 16 cores → max 32 total vCPU assignment
- Rarely all VMs busy simultaneously
```

### CPU Allocation by Workload
```
Light workload (web app, static content):
vCPU: 1-2
Type: Burstable (can spike)

Medium workload (database with light traffic):
vCPU: 2-4
Type: Reserved (consistent demand)

Heavy workload (cache server, heavy processing):
vCPU: 4-8
Type: Reserved minimum, burstable maximum

Memory-intensive (in-memory database):
vCPU: Can go lower than memory suggests
Ratio: 1 vCPU : 8-16GB RAM
```

### CPU Priority
```bash
# Set CPU shares (relative priority)
# Higher number = more CPU time when contending

# In Proxmox:
# VM settings → Processors → CPU Priority

# In libvirt:
virsh schedinfo vm-name
cpu_shares : 1024       # Default

# Increase priority (more important VM)
virsh schedinfo vm-name --set cpu_shares=2048

# Decrease priority (less important VM)
virsh schedinfo vm-name --set cpu_shares=512
```

## Memory Management

### Memory Allocation Strategy
```
Allocation method:
- Assigned memory: Peak usage expected
- Reserved memory: Guaranteed available
- Ballooned memory: Can be reclaimed by host

Example VM (web server):
- Assigned: 4GB (peak usage with buffer)
- Reserved: 2GB (guaranteed always available)
- Ballooned to: 2GB (host can reclaim 2GB if needed)
```

### Memory Calculation
```bash
# Physical RAM available for VMs
Physical RAM: 64GB
Reserved for host OS: 4GB
Available: 64 - 4 = 60GB

# Allocation considering memory ballooning
VM1: 8GB assigned, 4GB reserved
VM2: 4GB assigned, 2GB reserved
VM3: 4GB assigned, 2GB reserved
VM4: 8GB assigned, 4GB reserved
Total assigned: 24GB
Total reserved: 12GB
Balloon capability: 24 - 12 = 12GB

# With ballooning:
- If all VMs need full memory: Assigned totals are reduced
- If some VMs idle: Balloon recovers 12GB
- More flexible than pure assignment
```

### Memory Monitoring
```bash
# Check memory per VM
virsh dommemstat vm-name
actual = 2048        # Currently using (in MB)
available = 4096     # Assigned total

# Monitor trends
for i in {1..10}; do
  echo "=== $(date) ==="
  virsh dommemstat vm-name | grep actual
  sleep 60
done

# Identify if memory is growing (leak)
# If actual increases over days/weeks without workload change:
# Possible memory leak
```

### Swap and OOM
```bash
# Check swap usage in VM
free -h
# Swap in use = bad (slow)

# Identify memory pressure
# In VM: cat /proc/pressure/memory
# Shows how much memory pressure system is under

# OOM killer logs
sudo dmesg | grep -i oom
# If appearing: VM needs more memory

# Fix:
# 1. Add more memory: virsh setmem vm-name 8GB
# 2. Or: Reduce running services
# 3. Or: Upgrade host hardware
```

## Storage Capacity Planning

### Storage Hierarchy
```
Tier 1 (Fast, Expensive): NVMe SSD
- OS and databases
- ~256-512GB typical
- Cost: $100-200

Tier 2 (Medium): SATA SSD
- Container storage, VM disks
- ~1-2TB typical
- Cost: $60-120 per TB

Tier 3 (Slow, Cheap): HDD
- Bulk storage, backups, archives
- ~8TB+ typical
- Cost: $10-20 per TB

Example 30TB total homelab:
- 256GB NVMe (OS): Tier 1
- 1TB SATA SSD (VM/Container): Tier 2
- 24TB HDD (Bulk/Backup): Tier 3
```

### Calculate Storage Needs
```
OS drives:
- Linux: 20-30GB
- Windows: 30-50GB

Per VM/Container:
- Application: 10-40GB
- Data: Variable (database, files, etc)
- Snapshots: Up to 50% of VM size

Backup storage:
- Should be ≥ Total data size

Example calculation:
5 VMs × 50GB = 250GB
Snapshots (20%) = 50GB
Database = 200GB
Total active data = 500GB
Backup space = 500GB
Total storage needed = 1TB minimum
```

### Storage Growth Monitoring
```bash
# Current usage
du -sh /*

# Growth trend
du -sh / | date >> /tmp/storage_log.txt
# Run weekly, compare growth rate

# Identify large files
find / -type f -size +1G -exec ls -lh {} \;

# Disk space by time
ls -lah /backups/ | awk '{print $9, $5}' | sort -k2 -rn | head -10
```

### Storage Optimization
```bash
# Remove old backups
find /backups -type f -mtime +90 -delete  # Delete > 90 days old

# Compress large files
tar czf large_file.tar.gz large_file
rm large_file

# Remove Docker dangling images
docker image prune -a

# Clean old logs
sudo journalctl --vacuum=100M  # Keep only 100MB

# Remove temp files
rm -rf /tmp/*
rm -rf /var/tmp/*
```

## Power Management

### Power Consumption Calculation
```
Device power draw:
CPU: 65-120W (idle: 20-30W)
Memory: 5W per 8GB
SSD: 2-5W
HDD: 8-12W each (idle: 1-3W)
Fans: 2-10W each
PSU efficiency: 85-90%
Overhead: 20%

Example system:
CPU: 65W
Memory (32GB): 20W
3× HDD: 30W
SSD: 3W
Fans: 5W
Subtotal: 123W
PSU (15% overhead): 141W
Real-world PSU load: 150-200W constant

Over 24h: 3.6-4.8 kWh/day
Over month: 108-144 kWh/month
Cost (at $0.12/kWh): $13-17/month
Annual: $156-204
```

### Reduce Power Consumption
```bash
# Check CPU frequency scaling
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Enable power saving
echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Monitor power usage
sudo apt-get install powertop
sudo powertop

# Disable unused devices
# BIOS/UEFI settings:
- Disable unused SATA ports
- Disable serial ports
- Disable unused NICs

# Virtual machine settings:
- Remove unused disks
- Remove unused network adapters
```

### Backup Power (UPS)
```
Recommend: UPS capacity = Shutdown time needed

Example:
- System power: 200W
- Shutdown time: 10 minutes
- UPS capacity needed: 200W × 10min = 33Wh

Real world: Get 1500VA (900W) UPS
- Safely powers system for ~20-30 minutes
- Allows graceful shutdown of all VMs
- Avoids data corruption from sudden loss
```

## Cost Tracking

### Operational Costs
```bash
# Track expenses
cat > homelab-costs.csv <<EOF
Date,Item,Cost,Category,Notes
2024-03-01,NVMe drive,150,Hardware,Samsung 980 Pro
2024-03-05,UPS battery,80,Maintenance,Annual replacement
2024-03-10,Power consumption,17,Utility,Monthly estimate
2024-03-15,Internet,60,Service,ISP bill
EOF

# Calculate monthly average
awk -F',' 'NR>1 && $4=="Monthly" {sum+=$3} END {print "Monthly: $"sum}' \
  homelab-costs.csv

# Annual projection
awk -F',' 'NR>1 && $4!="Hardware" {sum+=$3} END {print "Annual (ongoing): $"sum*12}' \
  homelab-costs.csv
```

### Hardware Investment ROI
```
Consider: Homelab cost vs cloud equivalent

Small homelab setup:
- Hardware (amortized): $50/month
- Power: $20/month
- Internet: $60/month
- Total: $130/month = $1,560/year

Cloud equivalent:
- VPS: $20/month
- Database: $30/month
- Storage: $20/month
- Bandwidth: $10/month
- Total: $80/month = $960/year

Homelab advantages:
- Learning/education value
- Full control
- No vendor lock-in
- Fun factor!
```

## Monitoring Resource Trends

### Collection Strategy
```bash
# Weekly resource collection
cat > collect-metrics.sh <<'EOF'
#!/bin/bash

# Collect data
date >> /tmp/metrics.txt
echo "=== CPU ===" >> /tmp/metrics.txt
uptime >> /tmp/metrics.txt
echo "=== Memory ===" >> /tmp/metrics.txt
free -h >> /tmp/metrics.txt
echo "=== Disk ===" >> /tmp/metrics.txt
df -h / >> /tmp/metrics.txt
echo "=== VMs ===" >> /tmp/metrics.txt
virsh list >> /tmp/metrics.txt
echo "" >> /tmp/metrics.txt
EOF

chmod +x collect-metrics.sh

# Run weekly
crontab -e
# 0 0 * * 0 /path/to/collect-metrics.sh
```

### Trend Analysis
```
Review quarterly:
- Is CPU utilization increasing? → Plan upgrade
- Is memory usage creeping up? → Right-size VMs
- Is disk space filling? → Add storage or archive
- Is power consumption higher? → Optimize

Graph the trends:
- If CPU goes from 20% to 60% in 6 months
- Upgrade hypervisor in 3-4 months (don't wait until full)
```

## Knowing When to Upgrade

### Upgrade Indicators
```
❌ Too late to upgrade:
- CPU hitting 95% regularly
- Memory causing OOM kills
- Disk completely full
- Power supply maxed out

⚠️ Time to plan upgrade:
- CPU hitting 70% under typical load
- Memory hitting 80% under typical load
- Disk 75% full
- Power supply 75% utilized

✅ Good upgrade timing:
- Projected to hit 70% in 6 months
- New workload requiring resources
- Hardware failure on aging equipment
- Opportunity to consolidate/improve
```

### Upgrade Planning
```
Approach 1: Add more of same
- Add RAM stick to existing machine
- Add more drives
- Add second network card
- Limited by hardware capabilities

Approach 2: Replace with newer
- More efficient (saves power)
- Better specs
- Warranty/support
- Can repurpose old hardware
- Higher upfront cost

Approach 3: Cluster/scale out
- Add second hypervisor host
- Distribute load across hosts
- High availability possible
- More complex management
- Best for serious homelabs

Recommendation for most:
- Approach 1 until maxed
- Then Approach 2 (replace)
- Approach 3 only if HA critical
```

## Rightsizing VMs & Containers

### Identify Over-Allocation
```bash
# VM currently allocated: 4 vCPU, 8GB RAM
# Monitor actual usage for 2 weeks

# Check actual CPU usage
vmstat 1 10 | awk '{print $13 + $14}'  # %us + %sy
# Result: 5-10% consistently

# Check actual memory
free -h
# Result: Using 1-2GB of 8GB

# Right-size to 2 vCPU, 4GB RAM
# Save 2 vCPU and 4GB for other workloads
```

### Container Resource Requests
```yaml
# Docker Compose example
services:
  web:
    image: nginx:latest
    deploy:
      resources:
        requests:
          memory: "256M"      # Minimum
          cpus: "0.25"        # Minimum
        limits:
          memory: "512M"      # Maximum
          cpus: "0.5"         # Maximum

# Monitor actual usage
docker stats web --no-stream

# If consistently:
# - Using < 50% limit → decrease limits
# - Using > 75% limit → increase limits
```

## Growth Scaling

### Service Addition Timeline
```
Month 1-3: Foundation
- 2-3 core services
- 5-10 containers/VMs
- 30-50% CPU utilization
- 50-60% memory utilization

Month 3-6: Expansion
- Add monitoring, metrics
- Add backup system
- Add DNS redundancy
- 40-60% resource utilization

Month 6-12: Consolidation
- Optimize existing services
- Consider HA/redundancy
- Plan first upgrade
- 60-75% resource utilization

Year 2: Growth planning
- Consider second hypervisor
- Evaluate cluster options
- Plan hardware refresh
- Improve documentation
```

### When to Stop Adding
```
Services are eating resources?
It's healthy to reach 70-80% utilization.

But consider stopping when:
- Each new service requires optimization
- Required upgrades every 6 months
- Maintenance time consuming
- Can't enjoy the learning anymore

Perfect homelab:
- 70% CPU under normal load
- 75% memory under normal load
- 70% disk capacity
- One upgrade every 18-24 months
- Time to tinker and learn
```

## Best Practices

- Always maintain 30% headroom on resources
- Plan upgrades 6 months in advance
- Monitor trends, not just current state
- Right-size based on actual usage, not guess
- Balance performance with simplicity
- Track costs to understand real expense
- Upgrade when it makes sense, not when full
- Keep growth sustainable
- Don't over-engineer early on
- Enjoy the process, not just the destination

---

✅ Resource management guide complete - scale sustainably as you grow
