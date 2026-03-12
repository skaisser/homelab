# ⚡ Performance Monitoring and Resource Tracking #maintenance #performance #monitoring #resources

Monitor system performance to identify bottlenecks, optimize resource allocation, and maintain stable homelab operations.

## Table of Contents

1. [Key Performance Metrics](#key-performance-metrics)
2. [htop for System Monitoring](#htop-for-system-monitoring)
3. [btop Modern Monitoring](#btop-modern-monitoring)
4. [Disk I/O Monitoring](#disk-io-monitoring)
5. [Network Monitoring](#network-monitoring)
6. [Combined Statistics with dstat](#combined-statistics-with-dstat)
7. [Netdata Lightweight Monitoring](#netdata-lightweight-monitoring)
8. [Performance Baselines](#performance-baselines)
9. [Identifying Bottlenecks](#identifying-bottlenecks)
10. [Troubleshooting Performance](#troubleshooting-performance)

## Key Performance Metrics

### What to Monitor

```bash
# CPU Metrics
# - Usage percentage (user, system, idle)
# - Load average (1min, 5min, 15min)
# - Context switches
# - Per-process CPU utilization

# Memory Metrics
# - Available memory
# - Cache vs. used memory
# - Swap usage
# - Per-process memory footprint

# Disk Metrics
# - I/O read/write rates
# - Disk utilization percentage
# - Queue depth
# - Per-process disk I/O

# Network Metrics
# - Bandwidth in/out
# - Packet loss
# - Interface errors
# - Per-process network usage

# System Metrics
# - Temperature
# - Fan speeds
# - Uptime
# - Process count
```

## htop for System Monitoring

### Install htop

```bash
# Install htop
sudo apt-get install htop

# Run interactive monitoring
htop

# Export data for analysis
htop --export-htm htop-snapshot.html
```

### htop Commands

```bash
# Launch htop
htop

# Key controls:
# F1 (?) - Help
# F2 - Setup/Configure
# F3 - Search
# F4 - Filter
# F5 - Tree view
# F6 - Sort by column
# F9 - Kill process
# q - Quit

# Monitor specific user
htop -u username

# Highlight process
htop -H

# Show only processes using >10% CPU
htop --filter "CPU>10"
```

### Monitor CPU-Intensive Processes

```bash
# Sort by CPU usage
htop -o %CPU

# Find top CPU consumers
ps aux --sort=-%cpu | head -10

# Watch CPU usage over time
watch -n 1 'top -bn1 | grep "%Cpu"'
```

### Monitor Memory-Intensive Processes

```bash
# Sort by memory in htop
htop -o VIRT

# Find top memory consumers
ps aux --sort=-%mem | head -10

# Show memory details
free -h
cat /proc/meminfo | grep -E "MemTotal|MemAvail|Cached"
```

## btop Modern Monitoring

### Install btop

```bash
# Install btop (modern replacement for htop)
sudo apt-get install btop

# Or build from source
git clone https://github.com/aristocratos/btop.git
cd btop && make && sudo make install

# Run btop
btop
```

### btop Features

```bash
# btop advantages over htop:
# - Better color scheme and visual hierarchy
# - Built-in graphs
# - GPU monitoring (if supported)
# - More detailed process info
# - Mouse support
# - Theme customization

# Configuration file
~/.config/btop/btop.conf

# Common commands in btop:
# q - Quit
# ? - Help
# p - Process preset
# k - Kill process
# + - Increase graph scale
# - - Decrease graph scale
```

### Monitor with btop

```bash
# Run btop with custom theme
btop --theme default

# Show process tree
btop  # Then press 'p' for presets

# Monitor in non-interactive mode (script-friendly)
# btop exports data to /tmp/btop_data.json
```

## Disk I/O Monitoring

### iostat for I/O Statistics

```bash
# Install sysstat
sudo apt-get install sysstat

# Show disk I/O statistics
iostat -x 1 10  # 10 iterations, 1 second interval

# Watch specific disk
iostat -x sda 1 10

# Detailed output with all metrics
iostat -dx 1 5
```

### Understanding iostat Output

```bash
# Key metrics:
# r/s - Read requests per second
# w/s - Write requests per second
# rMB/s - Read data rate (MB/s)
# wMB/s - Write data rate (MB/s)
# %util - Disk utilization percentage

# Examples:
iostat -x 1 5
# Watch for %util > 80% (bottleneck)
# High queue depth indicates congestion
```

### iotop for Process-Level Disk I/O

```bash
# Install iotop
sudo apt-get install iotop

# Run iotop (requires root)
sudo iotop

# Show only processes with disk I/O
sudo iotop --only

# Sort by write speed
sudo iotop --order=io

# Monitor non-interactively
sudo iotop -n 5 -b
```

### Monitor Disk Queue

```bash
# Check queue depth
cat /sys/block/sda/queue/nr_requests

# Monitor queue over time
watch -n 1 'cat /sys/block/sda/requests'

# Check I/O scheduler
cat /sys/block/sda/queue/scheduler

# Best scheduler options:
# noop - No scheduling (for SSDs)
# deadline - Low latency
# cfq - Fair queuing (default)

# Change scheduler
echo "noop" | sudo tee /sys/block/sda/queue/scheduler
```

## Network Monitoring

### iftop for Network Bandwidth

```bash
# Install iftop
sudo apt-get install iftop

# Run iftop
sudo iftop -i eth0

# Show bytes instead of packets
sudo iftop -n

# Monitor specific host
sudo iftop -f "host 192.168.1.100"

# Sort by different columns
# n - Sort by source
# d - Sort by destination
# s - Sort by source port
# d - Sort by destination port
# t - Sort by total bandwidth
```

### nethogs for Process-Level Network

```bash
# Install nethogs
sudo apt-get install nethogs

# Run nethogs
sudo nethogs eth0

# Show network per-process
sudo nethogs  # Shows which process uses network

# Group by protocol
sudo nethogs -p
```

### Network Statistics with ss

```bash
# Show network connections
ss -tlnp

# Monitor network interface
watch -n 1 'ip -s link'

# Show packet statistics
netstat -i

# Monitor traffic rate
iftop -i eth0 -n

# Check bandwidth utilization
grep "eth0" /proc/net/dev
```

## Combined Statistics with dstat

### Install dstat

```bash
# Install dstat
sudo apt-get install dstat

# Run dstat (combines multiple metrics)
dstat

# Monitor CPU and disk together
dstat -c -d

# Monitor all with color
dstat -tcms
```

### dstat Command Examples

```bash
# CPU, disk, and network
dstat -cdn

# All metrics
dstat -a

# Export to CSV
dstat -o /tmp/monitor.csv

# MySQL statistics (if available)
dstat --mysql

# Custom monitoring interval
dstat --delay 2 --count 60
```

## Netdata Lightweight Monitoring

### Install Netdata

```bash
# Install Netdata
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
sh /tmp/netdata-kickstart.sh --stable-channel --disable-telemetry

# Or Docker
docker run -d --name=netdata \
  -p 19999:19999 \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  netdata/netdata:stable
```

### Access Netdata

```bash
# Web interface
# http://localhost:19999

# API access
curl http://localhost:19999/api/v1/allmetrics?format=json | jq '.data'

# Get specific metric
curl http://localhost:19999/api/v1/data?chart=system.cpu&points=100
```

### Netdata Features

```bash
# Real-time monitoring dashboards
# - CPU, memory, disk usage
# - Network interfaces
# - Process metrics
# - System services

# Alerts and notifications
# - Configure /etc/netdata/health.d/

# Export capabilities
# - InfluxDB
# - Prometheus
# - Graphite
```

## Performance Baselines

### Establish Baseline

```bash
#!/bin/bash
# File: /usr/local/bin/establish-baseline.sh

BASELINE_DIR="/home/user/performance-baselines"
mkdir -p "$BASELINE_DIR"
BASELINE_FILE="$BASELINE_DIR/baseline-$(date +%Y%m%d).txt"

{
    echo "Performance Baseline - $(date)"
    echo "=============================="
    echo ""

    echo "System Information:"
    uname -a
    nproc --all
    free -h
    df -h /

    echo ""
    echo "Idle CPU load (after 5 minutes quiet):"
    sleep 300
    uptime

    echo ""
    echo "Memory baseline:"
    free -h
    cat /proc/meminfo | grep -E "MemAvail|Cached|Buffers"

    echo ""
    echo "Disk baseline:"
    iostat -d 1 3

    echo ""
    echo "Network baseline:"
    ip -s link

} > "$BASELINE_FILE"

echo "Baseline saved to: $BASELINE_FILE"
```

### Compare Against Baseline

```bash
#!/bin/bash
# Compare current performance to baseline

BASELINE_FILE="/home/user/performance-baselines/baseline-initial.txt"

echo "Current vs Baseline Comparison"
echo "============================="
echo ""

# CPU Load
echo "CPU Load:"
echo "Baseline: $(grep 'load average' $BASELINE_FILE | head -1)"
echo "Current: $(uptime)"

# Memory
echo ""
echo "Memory:"
echo "Baseline:"
grep "MemAvail" "$BASELINE_FILE"
echo "Current:"
free -h | grep Mem
```

## Identifying Bottlenecks

### CPU Bottleneck

```bash
# Check CPU usage
top -bn1 | head -3

# High system time indicates kernel bottleneck
# High user time indicates application bottleneck

# Find CPU-bound processes
ps aux --sort=-%cpu | head -5

# Check for context switches (high = contention)
vmstat 1 5 | tail -1
```

### Memory Bottleneck

```bash
# Check swap usage (should be minimal)
free -h | grep Swap

# If swap is high, you need more RAM
swapon --show

# Check page faults
vmstat 1 5
# 'pi' (pages in) and 'po' (pages out) should be ~0
```

### Disk I/O Bottleneck

```bash
# Check disk utilization
iostat -x 1 3 | grep -E "^sda|%util"

# If %util > 80% regularly, you have I/O bottleneck
# Monitor queue depth
iostat -x 1 5 | grep -E "aqu-sz"

# Find processes causing I/O
iotop --only --batch --iter=5
```

### Network Bottleneck

```bash
# Check bandwidth
iftop -i eth0 -n

# Check for dropped packets
ip -s link | grep -E "RX|TX|drop"

# Monitor connection queue
ss -s | grep -E "estab|listen"

# Check for TCP retransmissions
netstat -s | grep -i retrans
```

## Troubleshooting Performance

### High CPU Usage

```bash
#!/bin/bash
# Diagnose high CPU usage

echo "Top CPU processes:"
ps aux --sort=-%cpu | head -5

echo "CPU time by process:"
ps -eo pid,user,%cpu,time,comm --sort=-%cpu | head -10

# Check if CPU is hitting clock limits
cat /proc/cpuinfo | grep MHz

# Monitor system load
watch -n 1 'top -bn1 | head -3'
```

### Memory Pressure

```bash
# Show memory pressure
cat /proc/pressure/memory

# Check OOM killer logs
journalctl -u kernel --grep=OOM -r

# Monitor memory pressure over time
watch -n 1 'cat /proc/pressure/memory'

# If pressure is high, identify culprit
ps aux --sort=-%mem | head -5
```

### Disk I/O Saturation

```bash
# Monitor I/O metrics
iostat -dx 1 10

# Find top I/O processes
iotop --only --batch --iter=10

# Check for stuck processes
lsof -p [pid] | grep deleted

# Increase I/O buffer
sudo sysctl -w vm.dirty_writeback_centisecs=100
```

### Network Congestion

```bash
# Check packet loss
ping -c 100 8.8.8.8 | grep -i loss

# Monitor connection states
watch -n 1 'ss -s'

# Check for connection limit
sysctl net.ipv4.tcp_max_syn_backlog

# Monitor active connections
netstat -an | wc -l
```

### Performance Diagnostic Script

```bash
#!/bin/bash
# File: /usr/local/bin/performance-diagnostic.sh

echo "System Performance Diagnostic"
echo "============================"
date

echo ""
echo "1. CPU Analysis:"
echo "Load average: $(uptime | awk -F'load average:' '{print $2}')"
echo "CPU usage: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')"
echo "Top processes:"
ps aux --sort=-%cpu | head -3 | tail -2

echo ""
echo "2. Memory Analysis:"
echo "Usage: $(free -h | grep Mem | awk '{print $3" / "$2}')"
echo "Swap: $(free -h | grep Swap | awk '{print $3" / "$2}')"
echo "Top processes:"
ps aux --sort=-%mem | head -3 | tail -2

echo ""
echo "3. Disk I/O Analysis:"
iostat -dx 1 3 | tail -2

echo ""
echo "4. Network Analysis:"
iftop -n -i eth0 -s 1 -t 2>/dev/null | head -10

echo ""
echo "5. System Health:"
systemctl list-units --type service --state failed
```

---

✅ Establish performance baselines, monitor key metrics continuously, identify and resolve bottlenecks proactively
