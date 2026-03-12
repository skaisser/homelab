# 🔧 System Problems & Debugging Guide #troubleshooting #system #linux #debugging

Comprehensive guide to diagnosing and fixing boot failures, filesystem issues, resource exhaustion, and other critical system problems.

## Table of Contents
1. [Boot Failures](#boot-failures)
2. [Filesystem Issues](#filesystem-issues)
3. [Resource Exhaustion](#resource-exhaustion)
4. [Disk Space Problems](#disk-space-problems)
5. [Permission Errors](#permission-errors)
6. [Systemd Service Failures](#systemd-service-failures)
7. [Kernel Issues](#kernel-issues)
8. [Hardware Diagnostics](#hardware-diagnostics)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Boot Failures

### GRUB Issues

#### Stuck at GRUB prompt
```bash
# List available boot entries
ls -la /boot/grub

# Check GRUB configuration
cat /etc/default/grub

# Regenerate GRUB config
sudo update-grub

# Reinstall GRUB to disk (if needed)
sudo grub-install /dev/sda

# Test GRUB installation
sudo grub-install --test-load-driver ext2
```

#### Boot entry not appearing
```bash
# List current boot entries
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Set default boot entry
sudo grub-set-default 0  # 0 is first entry

# Check GRUB environment
cat /boot/grub/grubenv

# Manually add boot entry in /etc/grub.d/40_custom
sudo nano /etc/grub.d/40_custom
# Add: menuentry "Ubuntu" { linux /vmlinuz ... }

# Regenerate after edit
sudo update-grub
```

### UEFI Boot Issues
```bash
# Check boot order
sudo efibootmgr

# Create new EFI boot entry
sudo efibootmgr -c -d /dev/sda -p 1 -L "Ubuntu" -l "\EFI\ubuntu\shimx64.efi"

# Remove boot entry
sudo efibootmgr -b 0000 -B  # replace 0000 with entry number

# Set default boot entry
sudo efibootmgr -n 0000

# Reset boot order
sudo efibootmgr -o 0000,0001,0002
```

### Emergency Boot Modes
```bash
# Boot into recovery/emergency mode by editing GRUB:
# 1. At GRUB menu press 'e'
# 2. Find linux line, append: init=/bin/bash
# 3. Press Ctrl+X to boot

# Or boot to systemd recovery target
# Press 'e' at GRUB, change 'ro quiet splash' to:
# systemd.unit=rescue.target

# Once in recovery mode, remount root as writable
mount -o remount,rw /
```

## Filesystem Issues

### Check Filesystem Health
```bash
# Check filesystem integrity (unmount first!)
sudo umount /dev/sda1
sudo fsck /dev/sda1

# Or use e2fsck for ext4
sudo e2fsck -n /dev/sda1  # -n = read-only check
sudo e2fsck -y /dev/sda1  # -y = auto-repair

# Check specific filesystem type
sudo fsck.ext4 /dev/sda1

# Schedule check on next boot
sudo touch /forcefsck
sudo shutdown -r now

# View filesystem type
df -T

# Check inode usage
df -i
```

### Mount Problems
```bash
# View current mounts
mount

# Mount with debugging
sudo mount -v /dev/sda1 /mnt

# Mount read-only
sudo mount -o ro /dev/sda1 /mnt

# Mount with specific options
sudo mount -o noexec,nosuid,nodev /dev/sda1 /mnt

# Remount existing with new options
sudo mount -o remount,rw /dev/sda1 /mnt

# Check mount permissions
sudo mount | grep /mnt

# Unmount safely
sudo umount /mnt

# Force unmount if needed
sudo umount -f /mnt

# Lazy unmount (unmount when no longer in use)
sudo umount -l /mnt
```

### Corrupted Filesystem Recovery
```bash
# Attempt automatic repair with safe options
sudo fsck -n /dev/sda1  # Dry run first

# Attempt repair
sudo fsck -y /dev/sda1

# For ext4, try recovery
sudo e2fsck -p /dev/sda1

# Check filesystem journal
sudo tune2fs -l /dev/sda1 | grep -i journal

# Replay journal
sudo fsck.ext4 -n /dev/sda1

# Backup critical data if recovery fails
sudo mount -o ro /dev/sda1 /mnt
sudo tar czf ~/filesystem_backup.tar.gz /mnt
```

## Resource Exhaustion

### CPU Issues
```bash
# View real-time CPU usage
top

# Better interactive view
htop

# Show CPU per core
cat /proc/cpuinfo | grep processor

# Check CPU frequency
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq

# List top CPU consumers
ps aux --sort=-%cpu | head -11

# Use pidstat for detailed per-process CPU
sudo apt-get install sysstat
pidstat 1 10  # 1 second samples, 10 iterations
```

### Memory Issues
```bash
# View memory usage
free -h

# Detailed memory info
cat /proc/meminfo

# Top memory consumers
ps aux --sort=-%mem | head -11

# Memory map of process
cat /proc/PID/maps

# Check swap usage
swapon -s

# Monitor memory in real-time
watch -n 1 free -h
```

### Identifying Resource Leaks
```bash
# Monitor process over time
while true; do ps aux | grep processname | grep -v grep; sleep 60; done

# Use /usr/bin/time to profile process
/usr/bin/time -v /path/to/program

# strace system calls and timing
sudo strace -c /path/to/program

# Track memory growth
smem -s pss -p processname
```

## Disk Space Problems

### Identify Large Files
```bash
# Find largest files
find / -type f -exec du -h {} + | sort -rh | head -20

# Largest directories
du -sh /home/* /var/* /opt/* 2>/dev/null | sort -rh

# Check single directory
du -sh *

# Detailed breakdown
du -sh --apparent-size *

# Real vs apparent size
du -sh /*
```

### Clean Up Disk Space
```bash
# Remove apt cache
sudo apt-get clean

# Remove partial packages
sudo apt-get autoclean

# View package cache size
du -sh /var/cache/apt/

# Remove old journal logs
sudo journalctl --vacuum=100M  # Keep only 100MB

# Find and remove old logs
find /var/log -type f -mtime +30 -delete  # Delete logs older than 30 days

# Clear temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Check large files in /tmp
du -sh /tmp

# Remove snap cache (if using snaps)
sudo rm -rf /var/lib/snapd/snaps/*
```

### Monitor Disk Usage
```bash
# Real-time disk monitoring
watch -n 1 df -h

# Filesystem inode usage
df -i

# Check inodes per filesystem
df -iP / | tail -1

# Find many small files
find / -type f | wc -l

# Monitor disk I/O
iostat -x 1 5
```

## Permission Errors

### Fix Permission Issues
```bash
# Check file permissions
ls -la filename

# Change file permissions
chmod 644 filename        # rw-r--r--
chmod 755 directory       # rwxr-xr-x

# Change ownership
sudo chown user:group filename

# Recursive permission change
sudo chmod -R 755 /directory

# Change only files in directory
find /directory -type f -exec chmod 644 {} \;

# Change only directories
find /directory -type d -exec chmod 755 {} \;
```

### Diagnose Permission Problems
```bash
# Check user groups
id username

# Check sudo access
sudo -l

# Check file access
sudo -u otheruser cat /restricted/file  # Test as other user

# View permissions in octal
stat -c '%a %n' *

# Find setuid files (security risk)
find / -perm -4000 2>/dev/null
```

### Fix Common Permission Issues
```bash
# User can't write to home directory
sudo chown -R username:username /home/username

# Service can't access file
sudo chown serviceuser:servicegroup /path/to/file
sudo chmod 640 /path/to/file

# Group permissions for shared directory
sudo chmod 2770 /shared/directory  # setgid bit + rwxrwx---
sudo chgrp groupname /shared/directory
```

## Systemd Service Failures

### Check Service Status
```bash
# View service status
sudo systemctl status servicename

# Show detailed status
sudo systemctl show servicename

# List failed services
sudo systemctl list-units --failed

# Check service is enabled
sudo systemctl is-enabled servicename
```

### View Service Logs
```bash
# Recent logs
sudo journalctl -u servicename -n 50

# Real-time logs
sudo journalctl -u servicename -f

# Logs with timestamps
sudo journalctl -u servicename -o short-monotonic

# Today's logs only
sudo journalctl -u servicename --since today

# Time range
sudo journalctl -u servicename --since "2024-01-15" --until "2024-01-16"

# Priority levels
sudo journalctl -u servicename -p err  # Only errors
```

### Restart and Enable Services
```bash
# Restart service
sudo systemctl restart servicename

# Reload service (without stopping)
sudo systemctl reload servicename

# Stop service
sudo systemctl stop servicename

# Start service
sudo systemctl start servicename

# Enable on boot
sudo systemctl enable servicename

# Disable on boot
sudo systemctl disable servicename

# Reload systemd config after editing unit file
sudo systemctl daemon-reload
```

### Create/Debug Unit Files
```bash
# Example service file
sudo cat > /etc/systemd/system/myapp.service <<EOF
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=myappuser
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/python3 /opt/myapp/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Validate service file
sudo systemd-analyze verify /etc/systemd/system/myapp.service

# Debug service startup
sudo systemd-run -t bash -c 'ExecStart=/path/to/app'

# Check service environment
cat /proc/PID/environ | tr '\0' '\n'
```

## Kernel Issues

### Kernel Panic Detection
```bash
# Check for kernel panic messages
sudo dmesg | tail -50

# Monitor for panics
sudo dmesg -w

# Search for specific errors
sudo dmesg | grep -i panic

# Check kernel log
sudo cat /var/log/kern.log | tail -100
```

### OOM Killer Analysis
```bash
# Monitor OOM events
sudo grep -i oom /var/log/kern.log | tail -20

# Watch for OOM in real-time
sudo dmesg -w | grep -i oom

# Current memory pressure
cat /proc/pressure/memory

# Check OOM killer score for processes
cat /proc/*/oom_score | sort -rn | head -5

# Protect process from OOM killer
echo -1000 | sudo tee /proc/PID/oom_score_adj

# Make process easier to kill
echo 1000 | sudo tee /proc/PID/oom_score_adj
```

### Kernel Parameter Tuning
```bash
# View current kernel parameters
sysctl -a | grep -i parameter

# Set temporary parameter
sudo sysctl -w net.core.somaxconn=65535

# Set permanent parameter
echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.conf

# Apply changes
sudo sysctl -p

# View specific category
sysctl net.
sysctl vm.
sysctl kernel.
```

## Hardware Diagnostics

### CPU Testing
```bash
# Install stress test tools
sudo apt-get install stress-ng

# Stress all CPUs for 60 seconds
stress-ng --cpu 0 --timeout 60s

# Check CPU temperature
sudo apt-get install lm-sensors
sensors

# Monitor temperature
watch -n 1 sensors
```

### Memory Testing
```bash
# Run memtest
stress-ng --vm 1 --vm-bytes 80% --timeout 60s

# Check memory errors
sudo apt-get install memtester
sudo memtester 1024 1  # Test 1GB, 1 pass

# SMART monitoring
sudo apt-get install smartmontools
sudo smartctl -a /dev/sda
```

### Disk Testing
```bash
# Check disk health
sudo smartctl -a /dev/sda

# Enable SMART monitoring
sudo smartctl -s on /dev/sda

# Run disk performance test
sudo apt-get install fio
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread --bs=4k --direct=1 --size=1G --numjobs=4 --group_reporting /dev/sda

# View disk I/O stats
iostat -x 1
```

## Troubleshooting

### Issue: System won't boot
**Steps:**
1. Check BIOS/UEFI boot order
2. Verify boot disk is healthy
3. Boot into recovery mode and check filesystem
4. Check kernel messages: `sudo dmesg | grep -i error`
5. Try previous kernel version from GRUB menu

### Issue: High CPU usage
**Steps:**
1. Identify process: `top` or `htop`
2. Check what it's doing: `sudo strace -p PID`
3. Review service logs: `sudo journalctl -u servicename -f`
4. Kill runaway process: `kill -9 PID`
5. Check for loops or infinite processes

### Issue: Running out of disk space
**Steps:**
1. Identify large files: `du -sh /*`
2. Clean package cache: `sudo apt-get clean`
3. Remove old logs: `sudo journalctl --vacuum=100M`
4. Check for coredumps: `/var/crash/*`
5. Find and archive old backups

### Issue: Service failing to start
**Steps:**
1. Check status: `sudo systemctl status servicename`
2. View logs: `sudo journalctl -u servicename -n 100`
3. Check permissions on config files
4. Verify required dependencies are installed
5. Test service manually with same user/environment

## Best Practices

- Monitor system resources regularly with tools like htop, iostat
- Enable SMART monitoring on all disks
- Keep filesystem at <80% capacity for performance
- Review and archive old logs regularly
- Document systemd services and their dependencies
- Always test filesystem repairs before applying them
- Use journalctl for comprehensive service logging instead of text logs

---

✅ System troubleshooting guide complete - maintain healthy systems through monitoring and preventive maintenance
