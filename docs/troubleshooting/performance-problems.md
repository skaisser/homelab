# ⚡ Performance Troubleshooting & Optimization #troubleshooting #performance #optimization #debugging

Guide to identifying bottlenecks, analyzing resource usage, and resolving performance issues in your homelab.

## Table of Contents
1. [Identifying Bottlenecks](#identifying-bottlenecks)
2. [CPU Analysis](#cpu-analysis)
3. [Memory Investigation](#memory-investigation)
4. [Disk I/O Testing](#disk-io-testing)
5. [Network Performance](#network-performance)
6. [Docker Resource Management](#docker-resource-management)
7. [VM Resource Allocation](#vm-resource-allocation)
8. [Performance Monitoring](#performance-monitoring)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Identifying Bottlenecks

### Comprehensive System Analysis
```bash
# Quick overview of all resources
free -h && echo "---" && top -bn1 | head -15 && echo "---" && df -h

# View all system metrics
cat /proc/cpuinfo && echo "---" && cat /proc/meminfo && echo "---" && lsblk

# Check I/O wait percentage
iostat 1 3

# Network bandwidth usage
sudo apt-get install nethogs
sudo nethogs

# Interactive resource viewer
htop

# System load average interpretation
uptime
# Load average > CPU count = bottleneck
cat /proc/cpuinfo | grep processor | wc -l  # Number of CPUs
```

### Bottleneck Priority
```bash
# High CPU but low memory = CPU bottleneck
top

# High memory usage = Memory bottleneck
free -h

# High I/O wait in iostat = Disk bottleneck
iostat -x 1 3

# High network errors = Network bottleneck
ethtool -S eth0 | grep -i error
```

## CPU Analysis

### CPU Monitoring
```bash
# Real-time CPU usage
top

# Better interface for CPU monitoring
htop

# CPU load and frequency
watch -n 1 'cat /proc/cpuinfo | grep MHz && uptime'

# Per-core CPU usage
mpstat 1 3  # Requires: sudo apt-get install sysstat

# Top processes by CPU
ps aux --sort=-%cpu | head -11

# CPU context switches
vmstat 1 5
```

### CPU Detailed Investigation
```bash
# Monitor specific process CPU
pidstat -p PID 1 10  # Requires sysstat

# Show CPU cores and their usage
sar -u 1 3  # Requires sysstat

# CPU affinity and binding
taskset -cp PID  # Show CPU affinity
taskset -cp 0-3 PID  # Bind to cores 0-3

# Frequency scaling status
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check thermal throttling
sudo apt-get install stress-ng
sudo stress-ng --cpu 1 --timeout 30s
watch -n 1 'cat /sys/class/thermal/thermal_zone*/temp'
```

### Performance Profiling
```bash
# Use perf for CPU profiling
sudo apt-get install linux-tools-generic

# Record CPU events
sudo perf record -F 99 -p PID -- sleep 60

# Report results
sudo perf report

# Detailed function-level profiling
sudo perf record -g -p PID -- sleep 30
sudo perf report

# Identify hot functions
sudo perf top -p PID
```

## Memory Investigation

### Memory Usage Analysis
```bash
# Total memory overview
free -h

# Detailed memory breakdown
cat /proc/meminfo

# Per-process memory usage
ps aux --sort=-%mem | head -11

# Process memory map
cat /proc/PID/status | grep -i vm

# Detailed process memory
smem  # Requires: sudo apt-get install smem
smem -s pss -p processname

# Memory usage over time
watch -n 1 free -h
```

### Memory Leak Detection
```bash
# Monitor process memory growth
while true; do
  ps aux | grep processname | grep -v grep
  sleep 60
done

# Detailed memory usage per process
pidstat -r 1 10  # Requires sysstat

# Track memory allocations
valgrind --leak-check=full /path/to/program

# System-wide memory pressure
cat /proc/pressure/memory

# Swap usage
swapon -s
free -h | grep Swap
```

### Memory Caching and Buffer Investigation
```bash
# Check page cache size
free -h | grep Buff

# Memory in use for what
cat /proc/meminfo | grep -E "Cached|Buffers|Slab"

# Drop caches (careful - impacts performance)
sudo sync && sudo echo 3 > /proc/sys/vm/drop_caches

# Slab memory usage
cat /proc/slabinfo

# Check for memory fragmentation
cat /proc/buddyinfo
```

### Swap Analysis
```bash
# Check swap configuration
swapon -s

# Swap usage per process
for f in /proc/*/status; do awk '/VmSwap|Name/{printf $2 " " $3}END{print ""}' "$f"; done | sort -k 3 -n

# Disable swappiness for performance
echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Monitor swap usage
watch -n 1 'grep Swap /proc/meminfo'
```

## Disk I/O Testing

### I/O Performance Monitoring
```bash
# Real-time I/O statistics
iostat -x 1

# Disk I/O per process
iotop -o  # Requires: sudo apt-get install iotop

# Monitor specific device
iostat -x 1 /dev/sda

# Detailed I/O breakdown
iostat -d -m 1  # Megabytes/sec
```

### Disk Performance Testing
```bash
# Install fio (flexible I/O tester)
sudo apt-get install fio

# Sequential read performance
fio --name=seqread --ioengine=libaio --iodepth=32 --rw=read --bs=1M --direct=1 --size=10G --numjobs=4 --group_reporting /dev/sda

# Random read performance
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread --bs=4k --direct=1 --size=10G --numjobs=4 --group_reporting /dev/sda

# Random write performance
fio --name=randwrite --ioengine=libaio --iodepth=16 --rw=randwrite --bs=4k --direct=1 --size=10G --numjobs=4 --group_reporting /dev/sda

# Mixed workload
fio --name=mixed --ioengine=libaio --iodepth=16 --rw=randrw --rwmixread=70 --bs=4k --direct=1 --size=10G --numjobs=4 --group_reporting /dev/sda
```

### Disk Health and Performance
```bash
# Check disk queue depth
iostat -x 1 | grep -E "Device|sda"

# Monitor I/O wait
iostat -u 1 | grep "iowait"

# SMART health check
sudo smartctl -a /dev/sda

# SSD TRIM status
fstrim -v /

# Check filesystem efficiency
du -sh /home /var /opt

# Find large files affecting I/O
find / -type f -size +1G -exec ls -lh {} \;
```

## Network Performance

### Network Bandwidth Testing
```bash
# Install iperf3
sudo apt-get install iperf3

# Server side
iperf3 -s

# Client side (test to server)
iperf3 -c 192.168.1.50 -t 30

# Test in reverse
iperf3 -c 192.168.1.50 -R

# UDP performance
iperf3 -c 192.168.1.50 -u -b 100M

# Multiple streams
iperf3 -c 192.168.1.50 -P 4

# Bidirectional
iperf3 -c 192.168.1.50 --bidir
```

### Network Latency Testing
```bash
# Ping with latency histogram
ping -c 100 8.8.8.8 | tail -5

# MTR shows latency per hop
mtr -r -c 100 8.8.8.8

# Detailed latency measurement
fping -c 100 8.8.8.8 2>&1 | tail -10

# Netcat latency test
time nc -l -p 9999 > /dev/null &
time echo "test" | nc 127.0.0.1 9999
```

### Network Throughput Issues
```bash
# Check for packet loss
ping -c 100 8.8.8.8 | grep packet

# Monitor network drops
watch -n 1 'ethtool -S eth0 | grep drop'

# Check for errors
ethtool -S eth0 | grep -i error

# Monitor in real-time
nethogs eth0

# Check interface errors
ip -s link show eth0
```

## Docker Resource Management

### Monitor Container Resource Usage
```bash
# Real-time container stats
docker stats

# Specific container stats
docker stats containername

# Memory limit
docker stats --no-stream | grep -E "CONTAINER|containername"

# CPU percentage
docker inspect --format='{{.HostConfig.CpuPercent}}' containername
```

### Set Container Resource Limits
```bash
# Run with CPU limit (0.5 = 50% of one core)
docker run -d --cpus="0.5" --memory="512m" containername

# Limit to specific cores
docker run -d --cpus="0.5" --cpuset-cpus="0,1" containername

# Memory swap limit
docker run -d --memory="512m" --memory-swap="1024m" containername

# Blkio (disk I/O) limits
docker run -d --blkio-weight=300 containername
```

### Update Running Container Resources
```bash
# Update CPU limit
docker update --cpus="1" containername

# Update memory limit
docker update --memory="1024m" containername

# Update CPU shares
docker update --cpu-shares=512 containername
```

### View Detailed Container Info
```bash
# Full container configuration
docker inspect containername

# Just resource limits
docker inspect --format='{{json .HostConfig}}' containername | jq '.Memory, .MemorySwap, .CpuQuota'

# Resource reservation vs limits
docker inspect --format='{{json .HostConfig.MemoryReservation}}' containername
```

## VM Resource Allocation

### KVM/Libvirt VM Tuning
```bash
# List VMs
virsh list --all

# Check VM resource allocation
virsh dumpxml vmname | grep -E "vcpu|memory"

# Monitor VM CPU usage
virsh cpu-stats vmname

# Monitor VM memory
virsh dommemstat vmname

# Edit VM resources (offline only)
virsh edit vmname
# Modify: <vcpu> and <memory> values
# Then: virsh define vmname
```

### Proxmox LXC/VM Resource Tuning
```bash
# Edit VM in Proxmox
# Via UI: Datacenter > vmid > Hardware
# Or via config:
nano /etc/pve/qemu-server/100.conf

# Change CPU
cores: 4
cpu: host

# Change memory
memory: 2048
balloon: 1024

# Change disk
scsi0: local:100/vm-100-disk-0.qcow2,size=50G
```

### Performance Tips for VMs
```bash
# Enable CPU pinning (in VM config)
# vcpus: 0-3  # Pin to cores 0-3

# Check CPU NUMA settings
numactl --show

# Bind VM to specific NUMA node
# In Proxmox: set CPU affinity
# In libvirt: <numa><cell id='0' cpus='0-3'/></numa>

# Enable vhost-net for networking performance
# In VM XML: <interface type='virtio'><driver name='vhost'/></interface>

# Check VirtIO vs IDE (VirtIO faster)
virsh dumpxml vmname | grep -E "disk|emulator"
```

## Performance Monitoring

### Continuous Monitoring Setup
```bash
# Install monitoring tools
sudo apt-get install sysstat

# Enable and start service
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Collect data
sar -A 1 3

# View historical data
sar -u -f /var/log/sysstat/sa15  # Day 15
```

### Create Performance Baseline
```bash
# Record baseline during normal operation
sar -o /tmp/baseline.sar 1 3600 &

# After 1 hour, analyze
sar -f /tmp/baseline.sar -u
sar -f /tmp/baseline.sar -b  # I/O
sar -f /tmp/baseline.sar -r  # Memory

# Compare current to baseline
sar -f /tmp/baseline.sar -u > baseline_cpu.txt
sar -u 1 10 > current_cpu.txt
diff baseline_cpu.txt current_cpu.txt
```

### Trend Analysis
```bash
# Daily average CPU usage
sar -f /var/log/sysstat/sa15 -u | awk 'NR>3{print $0}' | tail -10

# Memory trends
sar -f /var/log/sysstat/sa15 -r | tail -10

# Disk I/O trends
sar -f /var/log/sysstat/sa15 -b | tail -10

# Export to CSV for graphing
sar -u -f /var/log/sysstat/sa15 | tail -n +3 > cpu_trends.csv
```

## Troubleshooting

### Issue: High CPU usage but can't identify process
**Steps:**
1. Run `top` or `htop` to see if process is visible
2. If not visible, it may be kernel thread: `ps aux | head -30`
3. Check for interrupts: `cat /proc/interrupts | sort -k2 -rn | head`
4. Use `perf top` to see kernel activity
5. Check for out-of-memory killer activity: `dmesg | grep -i oom`

### Issue: System slow with available memory
**Steps:**
1. Check cache: `free -h | grep Buff`
2. Check swap: `swapon -s` and `vmstat 1 3`
3. Check for memory pressure: `cat /proc/pressure/memory`
4. Look for swap thrashing: High `si/so` in vmstat
5. Drop caches and test: `sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches`

### Issue: Disk slow despite available space
**Steps:**
1. Run fio to test raw disk performance
2. Check for I/O errors: `dmesg | grep -i error`
3. Monitor I/O latency: `iostat -x 1`
4. Check SMART health: `sudo smartctl -a /dev/sda`
5. Test on different part of disk to identify bad sectors

### Issue: Docker containers performing poorly
**Steps:**
1. Check resource limits: `docker stats containername`
2. Increase if hitting limits: `docker update --memory="2048m"`
3. Check host system performance
4. Check for noisy neighbors: `docker stats`
5. Profile inside container if needed

## Best Practices

- Establish baseline metrics before optimization
- Monitor before and after any tuning
- Change one parameter at a time for proper attribution
- Use appropriate time windows for measurement (avoid peaks/troughs)
- Keep historical data for trend analysis
- Document all performance-related configuration changes
- Test performance changes in staging first
- Avoid premature optimization - only fix actual bottlenecks
- Regularly review performance metrics for capacity planning

---

✅ Performance troubleshooting guide complete - identify and eliminate bottlenecks systematically
