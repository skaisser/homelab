# 🚀 Performance Tuning & Optimization #best-practices #performance #optimization #tuning

Practical approach to optimizing homelab performance without premature optimization.

## Table of Contents
1. [Optimization Philosophy](#optimization-philosophy)
2. [Linux Kernel Tuning](#linux-kernel-tuning)
3. [Filesystem Optimization](#filesystem-optimization)
4. [Docker Performance](#docker-performance)
5. [VM Resource Allocation](#vm-resource-allocation)
6. [Network Optimization](#network-optimization)
7. [SSD Optimization](#ssd-optimization)
8. [Monitoring Strategy](#monitoring-strategy)
9. [Before & After Testing](#before--after-testing)
10. [Common Pitfalls](#common-pitfalls)

## Optimization Philosophy

### Measure First
```bash
# Never optimize without data!

# Establish baseline:
1. Measure current performance
2. Identify actual bottleneck
3. Apply specific fix
4. Measure improvement
5. Keep or revert based on results

# Tool workflow:
# Identify problem → Measure → Change → Verify
# Don't: Guess → Change → Hope it helps
```

### Identify Real Bottlenecks
```bash
# Check what's actually slow:

# CPU-bound? (High CPU usage, low wait time)
top
# Look for: %us (user) + %sy (system) > 80%

# I/O-bound? (High iowait percentage)
iostat -x 1
# Look for: %iowait > 20%

# Memory-bound? (High swap, OOM kills)
vmstat 1 3
# Look for: si/so (swap in/out) > 0

# Network-bound? (Packet loss, errors)
ethtool -S eth0 | grep -i error
# Look for: dropped, errors > 0
```

### Avoid Premature Optimization
```
DON'T optimize for:
- Hypothetical scenarios
- Peak load you won't hit
- 1% improvement worth hours of complexity
- Performance of unused features

DO optimize when:
- You have actual performance problem
- Measurement shows specific bottleneck
- Fix has acceptable complexity trade-off
- Improvement is significant (>20%)
```

## Linux Kernel Tuning

### Network Performance
```bash
# View current settings
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_max_syn_backlog

# Increase connection limits
echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" | sudo tee -a /etc/sysctl.conf

# TCP window scaling
echo "net.ipv4.tcp_window_scaling = 1" | sudo tee -a /etc/sysctl.conf

# Enable TCP keepalive
echo "net.ipv4.tcp_keepalives_intvl = 30" | sudo tee -a /etc/sysctl.conf

# Apply changes
sudo sysctl -p

# Verify applied
sysctl net.core.somaxconn
```

### Memory Management
```bash
# Reduce swappiness (prefer RAM)
# Default 60 (swap at 40% RAM full)
# Homelab: Set to 10-20
echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf

# Keep dirty pages longer in memory
echo "vm.dirty_ratio = 15" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio = 5" | sudo tee -a /etc/sysctl.conf

# Affect when flushing to disk
# Higher = better performance but more data loss risk
# Lower = safer but more I/O

# Example: Write-heavy workload (database)
echo "vm.dirty_ratio = 20" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_expire_centisecs = 3000" | sudo tee -a /etc/sysctl.conf

# Apply
sudo sysctl -p
```

### File Handle Limits
```bash
# Check current limits
ulimit -n
# Default often 1024, too low for busy servers

# Increase permanently
echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.conf

# Per-user limits
sudo nano /etc/security/limits.conf
# Add:
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535

# Apply
sudo sysctl -p

# Verify
ulimit -n  # After logout/login
```

## Filesystem Optimization

### ext4 Mount Options
```bash
# Check current mount options
mount | grep /

# Optimize for SSDs
sudo nano /etc/fstab

# Example lines:
# Before:
# /dev/sda1 / ext4 defaults,errors=remount-ro 0 1

# After (for SSD):
# /dev/sda1 / ext4 defaults,errors=remount-ro,noatime,nodiratime,discard 0 1

# Options explained:
# noatime: Don't update access time (less writes)
# nodiratime: Don't update directory access time
# discard: Enable TRIM for SSD wear leveling

# Remount without reboot
sudo mount -o remount,noatime,nodiratime,discard /

# Verify
mount | grep " / "
```

### TRIM for SSDs
```bash
# Check TRIM support
sudo lsblk --discard

# Manual TRIM
sudo fstrim -v /

# Automatic daily TRIM
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Verify running
sudo systemctl status fstrim.timer
sudo journalctl -u fstrim.timer -n 10
```

### Database Datafile Placement
```bash
# Best performance hierarchy:
1. NVMe SSD (OS + databases)
2. SATA SSD (containers, VMs)
3. 7200 RPM HDD (bulk storage, backups)

# Bad: Database on shared HDD with other workloads
# Good: Database on dedicated drive

# Example setup:
/dev/sda (SSD) → / (OS)
/dev/sdb (SSD) → /var/lib/mysql (Databases)
/dev/sdc (HDD) → /backups (Backups)
```

## Docker Performance

### Resource Limits
```bash
# Set reasonable limits to prevent runaway containers
docker run -d \
  --memory="512m" \
  --memory-swap="1024m" \
  --cpus="0.5" \
  --cpu-shares="512" \
  myapp:latest

# In docker-compose:
services:
  db:
    image: mysql:8
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### Storage Optimization
```bash
# Use bind mounts instead of volumes for performance
# ❌ Slower: Volume storage
docker run -v my_volume:/data ...

# ✓ Faster: Bind mount
docker run -v /host/path:/data ...

# Use tmpfs for temporary data
docker run --tmpfs /tmp:rw,size=1g ...

# Limit log size to prevent disk fill
# /etc/docker/daemon.json:
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# Reload
sudo systemctl reload docker
```

### Build Optimization
```bash
# Layer ordering: put unchanging layers first
# ❌ Bad: Changes to static code below
FROM ubuntu:20.04
COPY app.py /app/
RUN apt-get update && apt-get install -y python3

# ✓ Good: Static dependencies below changing code
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3
COPY app.py /app/

# Use .dockerignore
echo ".git" >> .dockerignore
echo "*.md" >> .dockerignore
echo "node_modules" >> .dockerignore
```

## VM Resource Allocation

### CPU Allocation
```bash
# Don't over-allocate CPUs
# Rule: Total vCPUs < physical cores × 1.5

# Physical: 8 cores
# Max vCPUs: 8 × 1.5 = 12 total

# Better: 8 × 1 = 8 total (no contention)

# Check current allocation
virsh dominfo vm-name | grep CPU
# Or in Proxmox UI

# Adjust in VM definition
virsh edit vm-name
# Change: <vcpu placement='static'>4</vcpu>

# CPU pinning (advanced)
# Bind VM cores to physical cores
# Reduces context switching
```

### Memory Allocation
```bash
# Don't allocate all RAM to VMs
# Rule: Total vRAM = (Physical RAM - 4GB) × 0.9

# Physical: 32GB
# Usable: 32 - 4 = 28GB
# VM total: 28 × 0.9 = 25.2GB (leave 25GB for VMs)

# Memory ballooning (dynamic allocation)
# Allows hypervisor to reclaim unused memory from VMs
# In KVM: memory.request < memory.limit

# Check memory usage
virsh dommemstat vm-name

# Hot-add memory to running VM
virsh setmem vm-name 4GB
```

## Network Optimization

### MTU Size
```bash
# Check current MTU
ip link show eth0

# Standard Ethernet: 1500 bytes
# Jumbo frames: 9000 bytes (requires network support)

# Test if network supports jumbo frames
ping -M do -s 8972 8.8.8.8  # 8972 + 28 header = 9000

# If works, increase MTU
sudo ip link set eth0 mtu 9000

# Make permanent
sudo nano /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    eth0:
      mtu: 9000

sudo netplan apply
```

### TCP Tuning
```bash
# Larger TCP buffers for high latency networks
echo "net.ipv4.tcp_rmem = 4096 87380 67108864" | \
  sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 67108864" | \
  sudo tee -a /etc/sysctl.conf

# Enable TCP Fast Open (Linux 3.13+)
echo "net.ipv4.tcp_fastopen = 3" | \
  sudo tee -a /etc/sysctl.conf

# Apply
sudo sysctl -p
```

## SSD Optimization

### I/O Scheduler
```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler
# Output: [none] mq-deadline kyber

# For SSDs, none is best (no queueing)
echo "none" | sudo tee /sys/block/sda/queue/scheduler

# Make permanent
echo "ACTION==\"add|change\", KERNEL==\"sd*\", ATTR{queue/scheduler}=\"none\"" | \
  sudo tee /etc/udev/rules.d/60-ssd-scheduler.rules

# Reload
sudo udevadm control --reload-rules
```

### NVME Specific
```bash
# Check NVME status
sudo nvme list

# Monitor NVME temperature
sudo nvme smart-log /dev/nvme0n1 | grep temperature

# Enable power saving
echo "auto" | sudo tee /sys/module/nvme_core/parameters/default_ps_max_latency_us

# Check for firmware updates
# Usually done in BIOS/UEFI
```

## Monitoring Strategy

### Establish Baselines
```bash
# Collect baseline data
for i in {1..7}; do
  sar -A -f /var/log/sysstat/sa$(printf "%02d" $i) > baseline_day$i.txt
done

# Compare before/after optimization
# Average CPU: 45% → 35% (22% improvement)
# Average I/O: 8ms → 5ms (37% improvement)
```

### Continuous Monitoring
```bash
# Long-term monitoring with Prometheus
sudo apt-get install prometheus

# Or use node_exporter for simple metrics
docker run -d \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  --net=host \
  prom/node-exporter

# Query metrics
curl http://localhost:9100/metrics | grep node_
```

## Before & After Testing

### Performance Test Script
```bash
#!/bin/bash
# save as: perf-test.sh

TEST_NAME=$1

# Collect baseline
echo "Starting test: $TEST_NAME"
echo "=== Baseline ===" > results_$TEST_NAME.txt

# CPU
echo "CPU Load:" >> results_$TEST_NAME.txt
uptime >> results_$TEST_NAME.txt

# Memory
echo "Memory Usage:" >> results_$TEST_NAME.txt
free -h >> results_$TEST_NAME.txt

# I/O
echo "Disk I/O:" >> results_$TEST_NAME.txt
iostat -x 1 3 | tail -10 >> results_$TEST_NAME.txt

# Network latency
echo "Network Latency:" >> results_$TEST_NAME.txt
ping -c 10 8.8.8.8 >> results_$TEST_NAME.txt

echo "Results saved to results_$TEST_NAME.txt"
```

### Comparison Method
```bash
# Before optimization
./perf-test.sh before

# Apply optimization
echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# After optimization (wait 5 min for warmup)
sleep 300
./perf-test.sh after

# Compare
diff results_before.txt results_after.txt
```

## Common Pitfalls

### Over-optimization
```
❌ Spent 3 hours tuning TCP for 2% improvement
❌ Complex kernel parameters for theoretical edge cases
❌ Cache optimization reducing memory for database

✓ Focus on:
- Actual measured bottleneck
- Simple, understandable changes
- Testing thoroughly before/after
```

### Stability vs Performance
```
❌ Increased vm.dirty_ratio to 40% → Potential data loss
❌ Disabled all logging for speed → Can't debug issues
❌ Removed monitoring to save resources → Can't identify problems

✓ Balance:
- Keep monitoring active
- Conservative with risky settings
- Document all changes
- Test thoroughly
```

### Environmental Differences
```
⚠️ Optimization on idle system might not apply under load
⚠️ Changes on one distro might not work on another
⚠️ Hardware-specific tuning doesn't transfer between systems

✓ Test:
- Under expected workload
- Over several hours/days
- With typical usage patterns
- In production-like environment
```

## Best Practices

- Measure first, optimize second
- Change one parameter at a time
- Document all changes and rationale
- Monitor impact for at least 24 hours
- Keep optimizations simple and reversible
- Avoid "because I read online" tuning
- Test in staging before production
- Most systems work fine without optimization
- Focus on actual bottlenecks, not guesses

---

✅ Performance tuning guide complete - optimize smartly, not blindly
