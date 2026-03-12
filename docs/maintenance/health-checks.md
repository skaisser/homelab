# 🏥 System Health Monitoring #maintenance #monitoring #health #smartctl

Implement comprehensive health monitoring to detect issues before they become critical failures. Monitor hardware, services, and resources systematically.

## Table of Contents

1. [What to Monitor](#what-to-monitor)
2. [SMART Disk Monitoring](#smart-disk-monitoring)
3. [CPU and Memory Checks](#cpu-and-memory-checks)
4. [Disk Usage Monitoring](#disk-usage-monitoring)
5. [Service Status Checks](#service-status-checks)
6. [Docker Health](#docker-health)
7. [Network Connectivity](#network-connectivity)
8. [Health Check Script](#health-check-script)
9. [Alerting on Failures](#alerting-on-failures)
10. [Scheduling Health Checks](#scheduling-health-checks)

## What to Monitor

### Critical Metrics

```bash
# Categories to monitor:
# 1. Hardware Health
#    - Disk SMART status
#    - CPU temperature
#    - System fan status

# 2. Storage
#    - Disk usage (root, data, backup)
#    - Inode usage
#    - Filesystem errors

# 3. Performance
#    - CPU load
#    - Memory utilization
#    - I/O patterns

# 4. Services
#    - Essential service status
#    - Port availability
#    - Process running state

# 5. Network
#    - Connectivity to gateway
#    - DNS resolution
#    - Network interfaces status
```

## SMART Disk Monitoring

### Install SMART Tools

```bash
# Install smartmontools
sudo apt-get install smartmontools

# Verify installation
smartctl --version
```

### Enable SMART Monitoring

```bash
# Start smartd daemon
sudo systemctl enable smartd
sudo systemctl start smartd

# Configure SMART monitoring
sudo nano /etc/smartd.conf

# Add monitoring for all disks:
/dev/sda -a -o on -S on -n standby,q -m root@example.com -M exec /usr/libexec/smartmontools/smartdnotify
/dev/sdb -a -o on -S on -n standby,q -m root@example.com -M exec /usr/libexec/smartmontools/smartdnotify

# Restart smartd
sudo systemctl restart smartd
```

### Check Disk Health

```bash
# List all disks
sudo smartctl --scan

# Check disk health
sudo smartctl -H /dev/sda

# View full SMART data
sudo smartctl -a /dev/sda

# Check specific attributes
sudo smartctl -A /dev/sda | grep -E "Reallocated_Sector|Reported_Uncorrect"

# Show test history
sudo smartctl -l selftest /dev/sda
```

### Run SMART Tests

```bash
# Start short self-test (2-5 minutes)
sudo smartctl -t short /dev/sda

# Start long self-test (hours)
sudo smartctl -t long /dev/sda

# Start conveyance test (for drives being shipped)
sudo smartctl -t conveyance /dev/sda

# Check test progress
sudo smartctl -l selftest /dev/sda

# Get test result after completion
sudo smartctl -a /dev/sda | tail -20
```

### Automated SMART Health Script

```bash
#!/bin/bash
# File: /usr/local/bin/check-disk-health.sh

DISKS=("/dev/sda" "/dev/sdb" "/dev/sdc")
HEALTH_LOG="/var/log/disk-health.log"

log_result() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG"
}

log_result "Disk Health Check"
log_result "=================="

for disk in "${DISKS[@]}"; do
    echo "Checking $disk..."

    # Check if disk exists
    if [ ! -b "$disk" ]; then
        log_result "WARNING: $disk not found"
        continue
    fi

    # Check health status
    health=$(sudo smartctl -H "$disk" 2>/dev/null | grep "PASSED\|FAILED")
    log_result "$disk: $health"

    # Check for reallocated sectors
    reallocated=$(sudo smartctl -A "$disk" 2>/dev/null | grep "Reallocated_Sector" | awk '{print $10}')
    if [ "$reallocated" -gt 0 ]; then
        log_result "WARNING: $disk has $reallocated reallocated sectors"
    fi

    # Check temperature
    temp=$(sudo smartctl -A "$disk" 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}')
    if [ "$temp" -gt 50 ]; then
        log_result "WARNING: $disk temperature is ${temp}C (high)"
    fi
done
```

## CPU and Memory Checks

### Check Current Usage

```bash
# CPU usage
top -bn1 | head -20

# Memory usage
free -h

# Both with more detail
watch -n 1 'top -bn1 | head -15 && echo && free -h'

# Load average
uptime

# Per-process breakdown
ps aux --sort=-%cpu | head -10
```

### CPU Temperature Monitoring

```bash
# Install temperature tools
sudo apt-get install lm-sensors

# Detect sensors
sudo sensors-detect

# Check temperatures
sensors

# Monitor continuously
watch -n 2 sensors

# Set temperature alerts
cat > /etc/modprobe.d/coretemp.conf << 'EOF'
options coretemp max_interval=1000
EOF
```

### Memory Leak Detection

```bash
#!/bin/bash
# Check for memory leaks

# Get process with highest memory growth over time
BASELINE_FILE="/tmp/memory-baseline-$(date +%Y%m%d).txt"
CURRENT_FILE="/tmp/memory-current-$(date +%Y%m%d).txt"

if [ -f "$BASELINE_FILE" ]; then
    ps aux --sort=-%mem | head -5 > "$CURRENT_FILE"
    diff "$BASELINE_FILE" "$CURRENT_FILE" | grep ">" | head -5
else
    ps aux --sort=-%mem | head -5 > "$BASELINE_FILE"
fi
```

## Disk Usage Monitoring

### Check Disk Space

```bash
# Overall disk usage
df -h

# Human-readable with inodes
df -ih

# Find largest directories
du -sh /* | sort -rh

# Find files larger than 100MB
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Monitor disk usage trend
for day in {1..7}; do
    echo "Day $day: $(df -h / | tail -1 | awk '{print $5}')"
done
```

### Disk Usage Alert Script

```bash
#!/bin/bash
# Alert when disk usage exceeds threshold

THRESHOLD=80  # percent
CRITICAL_THRESHOLD=90

check_disk() {
    local mount=$1
    local usage=$(df "$mount" | tail -1 | awk '{print int($5)}')

    if [ "$usage" -ge "$CRITICAL_THRESHOLD" ]; then
        echo "CRITICAL: $mount at ${usage}% capacity"
        # Send alert
        return 2
    elif [ "$usage" -ge "$THRESHOLD" ]; then
        echo "WARNING: $mount at ${usage}% capacity"
        # Log warning
        return 1
    else
        echo "OK: $mount at ${usage}% capacity"
        return 0
    fi
}

check_disk /
check_disk /home
check_disk /var
```

### Inode Usage Check

```bash
# Check inode usage
df -i

# Find directories with many inodes
find /home -type d -printf '%n %p\n' | sort -rn | head -10

# Alert on inode exhaustion
inode_usage=$(df -i / | tail -1 | awk '{print int($5)}')
if [ "$inode_usage" -gt 80 ]; then
    echo "WARNING: Root inode usage at ${inode_usage}%"
fi
```

## Service Status Checks

### Check Essential Services

```bash
# Status of specific services
systemctl status ssh
systemctl status mysql
systemctl status docker

# List all active services
systemctl list-units --type service --state running

# Check failed services
systemctl --failed
```

### Service Health Check Script

```bash
#!/bin/bash
# File: /usr/local/bin/check-services.sh

CRITICAL_SERVICES=("ssh" "networking" "cron")
IMPORTANT_SERVICES=("mysql" "docker" "postgresql")
LOG_FILE="/var/log/service-health.log"

check_service() {
    local service=$1
    local priority=$2

    if systemctl is-active "$service" > /dev/null 2>&1; then
        echo "✓ $service running" | tee -a "$LOG_FILE"
        return 0
    else
        echo "✗ $service FAILED ($priority)" | tee -a "$LOG_FILE"

        if [ "$priority" == "critical" ]; then
            # Attempt to restart critical service
            systemctl restart "$service"
        fi
        return 1
    fi
}

echo "[$(date)] Service Health Check" >> "$LOG_FILE"

for service in "${CRITICAL_SERVICES[@]}"; do
    check_service "$service" "critical"
done

for service in "${IMPORTANT_SERVICES[@]}"; do
    check_service "$service" "important"
done
```

### Port Availability Check

```bash
# Check if service is listening
sudo netstat -tlnp | grep ssh
sudo netstat -tlnp | grep :3306

# Or with ss (more modern)
ss -tlnp | grep 22
ss -tlnp | grep 3306

# Check if port is open from remote
nc -zv localhost 22
nc -zv localhost 3306
```

## Docker Health

### Check Docker Service

```bash
# Docker daemon status
systemctl status docker
docker ps

# Check for stuck containers
docker ps --filter "status=paused"

# View container logs for errors
docker logs container-name | tail -20

# Check resource usage
docker stats
```

### Container Health Script

```bash
#!/bin/bash
# Monitor Docker container health

echo "Docker Container Health Check"
docker ps --format "table {{.Names}}\t{{.Status}}" | while read name status; do
    if [[ "$status" == "Exited"* ]]; then
        echo "✗ FAILED: $name - $status"
    elif [[ "$status" == "Up"* ]]; then
        echo "✓ Running: $name"
    else
        echo "? Unknown: $name - $status"
    fi
done
```

## Network Connectivity

### Test Network Connectivity

```bash
# Test gateway connectivity
ping -c 3 192.168.1.1

# Test internet
ping -c 3 8.8.8.8

# Check DNS resolution
nslookup google.com
dig example.com

# Test specific ports
telnet remote-host 22
nc -zv remote-host 443
```

### Network Health Script

```bash
#!/bin/bash
# Network connectivity check

echo "Network Health Check"
echo "==================="

# Gateway reachability
if ping -c 1 -W 2 192.168.1.1 > /dev/null 2>&1; then
    echo "✓ Gateway reachable"
else
    echo "✗ Gateway unreachable"
fi

# DNS resolution
if nslookup google.com > /dev/null 2>&1; then
    echo "✓ DNS working"
else
    echo "✗ DNS failed"
fi

# Internet connectivity
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo "✓ Internet accessible"
else
    echo "✗ No internet"
fi

# Network interfaces
echo "Network interfaces:"
ip addr show | grep -E "^[0-9]|inet"
```

## Health Check Script

### Comprehensive Health Check

```bash
#!/bin/bash
# File: /usr/local/bin/full-health-check.sh

HEALTH_REPORT="/tmp/health-report-$(date +%Y%m%d-%H%M%S).txt"
EXIT_CODE=0

report() {
    local status=$1
    local message=$2
    echo "[$status] $message" | tee -a "$HEALTH_REPORT"
    if [ "$status" == "ERROR" ]; then
        EXIT_CODE=1
    fi
}

echo "System Health Check - $(date)" > "$HEALTH_REPORT"
echo "================================" >> "$HEALTH_REPORT"

# 1. Disk Health
report "INFO" "Checking disk health..."
sudo smartctl -H /dev/sda | grep -q "PASSED" && \
    report "OK" "Disk health: PASSED" || \
    report "ERROR" "Disk health: FAILED"

# 2. Disk Space
usage=$(df / | tail -1 | awk '{print int($5)}')
if [ "$usage" -gt 90 ]; then
    report "ERROR" "Root partition usage: ${usage}%"
elif [ "$usage" -gt 80 ]; then
    report "WARN" "Root partition usage: ${usage}%"
else
    report "OK" "Root partition usage: ${usage}%"
fi

# 3. Memory
free_mem=$(free -h | grep Mem | awk '{print $7}')
report "OK" "Free memory: $free_mem"

# 4. Load Average
load=$(uptime | awk -F'load average:' '{print $2}')
report "OK" "Load average: $load"

# 5. Critical Services
systemctl is-active ssh > /dev/null && \
    report "OK" "SSH service running" || \
    report "ERROR" "SSH service DOWN"

# 6. Network
ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1 && \
    report "OK" "Internet connectivity OK" || \
    report "ERROR" "No internet access"

echo "" >> "$HEALTH_REPORT"
echo "Report saved to: $HEALTH_REPORT"
exit $EXIT_CODE
```

## Alerting on Failures

### Email Alerts

```bash
# Send alert email
send_alert() {
    local subject=$1
    local message=$2

    echo "$message" | mail -s "$subject" admin@example.com
}

# Use in scripts
if [ "$disk_usage" -gt 90 ]; then
    send_alert "CRITICAL: Disk Usage High" "Root partition at ${disk_usage}%"
fi
```

### Systemd OnFailure Actions

```bash
# Create alert service
cat > /etc/systemd/system/system-health-alert.service << 'EOF'
[Unit]
Description=System Health Alert
OnFailure=send-alert.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/send-alert.sh "Service failed"
EOF

# Send alert when service fails
cat > /usr/local/bin/send-alert.sh << 'EOF'
#!/bin/bash
echo "$1" | mail -s "System Alert" admin@example.com
EOF
```

## Scheduling Health Checks

### Cron-Based Scheduling

```bash
# Edit crontab
crontab -e

# Hourly health check
0 * * * * /usr/local/bin/full-health-check.sh

# Daily detailed report
0 2 * * * /usr/local/bin/full-health-check.sh > /tmp/daily-health.txt 2>&1

# Weekly SMART test
0 3 * * 0 sudo smartctl -t short /dev/sda
```

### Systemd Timer

```bash
# Create service: /etc/systemd/system/health-check.service
[Unit]
Description=Homelab Health Check
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/full-health-check.sh
StandardOutput=journal

# Create timer: /etc/systemd/system/health-check.timer
[Unit]
Description=Homelab Health Check Timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target

# Enable
sudo systemctl daemon-reload
sudo systemctl enable --now health-check.timer
```

---

✅ Implement comprehensive health monitoring covering disks, resources, services, and network
