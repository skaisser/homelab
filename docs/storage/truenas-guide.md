# 🗃️ TrueNAS SCALE Administration Guide #truenas #storage #kubernetes #docker #zfs

Comprehensive guide for managing TrueNAS SCALE, focusing on its unique features as a hyperconverged infrastructure solution.

## 📋 Table of Contents
- [Storage Management](#storage-management)
- [Apps and Containers](#apps-and-containers)
- [Virtual Machines](#virtual-machines)
- [Network Configuration](#network-configuration)
- [System Management](#system-management)
- [Backup Solutions](#backup-solutions)
- [Troubleshooting](#troubleshooting)

## 📁 Storage Management

### ZFS Pool Operations
```bash
# List pools
zpool list

# Pool status and health
zpool status pool_name

# Import pool
zpool import pool_name

# Export pool
zpool export pool_name
```

### Dataset Management
```bash
# Create dataset
zfs create pool_name/dataset_name

# Set compression
zfs set compression=lz4 pool_name/dataset_name

# Set quota
zfs set quota=100G pool_name/dataset_name
```

### Snapshot Management
```bash
# Create snapshot
zfs snapshot pool_name/dataset_name@snapshot_name

# List snapshots
zfs list -t snapshot

# Roll back to snapshot
zfs rollback pool_name/dataset_name@snapshot_name
```

## 🐳 Apps and Containers

### Apps Management
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs container_name

# View container details
docker inspect container_name
```

### Container Shell Access
```bash
# Access container shell
docker exec -it container_name /bin/bash

# Copy files to container
docker cp /local/path container_name:/container/path

# Copy files from container
docker cp container_name:/container/path /local/path
```

### Docker Compose Operations
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View service logs
docker-compose logs -f service_name

# Restart service
docker-compose restart service_name
```

## 🖥 Virtual Machines

### VM Operations
```bash
# List VMs
virsh list --all

# Start VM
virsh start vm_name

# Stop VM
virsh shutdown vm_name

# Force stop VM
virsh destroy vm_name
```

### VM Management
```bash
# Edit VM configuration
virsh edit vm_name

# Show VM information
virsh dominfo vm_name

# Connect to VM console
virsh console vm_name
```

## 📶 Network Configuration

### Interface Management
```bash
# Show interfaces
ip addr show

# View network status
nmcli device status

# Configure interface
nmcli connection modify eth0 ipv4.addresses "192.168.1.100/24"
```

### VLAN Configuration
```bash
# Create VLAN interface
vconfig add eth0 100

# Remove VLAN interface
vconfig rem eth0.100
```

## ⚙️ System Management

### Service Control
```bash
# List services
systemctl list-units --type=service

# Check service status
systemctl status service_name

# Restart service
systemctl restart service_name
```

### System Updates
```bash
# Check update status
apt update

# List available updates
apt list --upgradable

# Apply updates
apt upgrade
```

## 💾 Backup Solutions

### Replication Tasks
```bash
# Create replication task
zfs send pool_name/dataset_name@snapshot | zfs receive backup_pool/dataset_name

# Incremental replication
zfs send -i pool_name/dataset_name@snap1 pool_name/dataset_name@snap2 | zfs receive backup_pool/dataset_name
```

### Rsync Backup
```bash
# Backup with rsync
rsync -avz /source/ user@remote:/destination/

# Backup with progress
rsync -avz --progress /source/ user@remote:/destination/
```

## 🔧 Troubleshooting

### System Logs
```bash
# View system logs
journalctl -xe

# View service logs
journalctl -u service_name

# Monitor logs in real-time
tail -f /var/log/messages
```

### ZFS Diagnostics
```bash
# Check pool health
zpool status -v

# Scrub pool
zpool scrub pool_name

# Clear pool errors
zpool clear pool_name
```

### Network Diagnostics
```bash
# Test connectivity
ping host

# Check ports
netstat -tuln

# Trace route
traceroute host
```

## 💡 Pro Tips

1. **Performance Optimization**
   - Use appropriate record sizes for datasets
   - Enable compression where suitable
   - Monitor ARC usage
   - Use SSD for cache/log devices

2. **Security Best Practices**
   - Keep system updated
   - Use strong passwords
   - Implement network segmentation
   - Regular security audits

3. **Maintenance Schedule**
   - Regular ZFS scrubs
   - Snapshot management
   - Log rotation
   - Backup verification

## 📘 Additional Resources

- [TrueNAS SCALE Documentation](https://www.truenas.com/docs/scale/)
- [TrueNAS Community](https://www.truenas.com/community/)
- [ZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

> 💡 **Note**: Always test commands in a safe environment first and ensure you have proper backups before making system changes.

## 📊 System Jobs

### List Active Jobs
```bash
# List all running jobs
systemctl list-jobs

# Show specific job details
systemctl status job_name

# List failed jobs
systemctl --failed
```

### Job Control
```bash
# Stop/Kill a job
systemctl stop job_name
systemctl kill job_name

# Restart a job
systemctl restart job_name

# Reset failed job status
systemctl reset-failed job_name
```

## ⚙️ Service Management

### Service Operations
```bash
# List all services
systemctl list-units --type=service

# Check service status
systemctl status service_name

# Start/Stop service
systemctl start service_name
systemctl stop service_name

# Enable/Disable on boot
systemctl enable service_name
systemctl disable service_name
```

## 📅 Task Scheduling

### Cron Jobs
```bash
# Edit user crontab
crontab -e

# List user cron jobs
crontab -l

# View system cron jobs
cat /etc/crontab
```

### Example Cron Entries
```bash
# Run daily at 2 AM
0 2 * * * /usr/local/bin/backup_script.sh

# Run every 5 minutes
*/5 * * * * /usr/local/bin/check_service.sh

# Run weekly on Sunday at 1 AM
0 1 * * 0 /usr/local/bin/weekly_maintenance.sh
```

## 📋 Job Monitoring

### View Job Logs
```bash
# View system journal
journalctl

# Follow job logs in real-time
journalctl -f -u job_name

# View logs since last boot
journalctl -b -u job_name

# Show logs with timestamps
journalctl --since "1 hour ago" -u job_name
```

### Resource Usage
```bash
# Monitor process resources
top -c

# View specific job resources
systemctl status job_name

# Check CPU/Memory usage
ps aux | grep job_name
```

## 🔧 Troubleshooting

### Common Issues

1. **Failed Jobs**
   ```bash
   # Check job status
   systemctl status job_name
   
   # View error logs
   journalctl -xe -u job_name
   ```

2. **Stuck Jobs**
   ```bash
   # List hanging jobs
   systemctl list-jobs
   
   # Force stop job
   systemctl kill -s SIGKILL job_name
   ```

3. **Resource Issues**
   ```bash
   # Check system resources
   top
   
   # View process tree
   pstree -p job_pid
   ```

### Best Practices

#### Job Management
- Use descriptive job names
- Set appropriate timeouts
- Implement logging
- Monitor resource usage

#### Scheduling
- Stagger job start times
- Set realistic intervals
- Consider dependencies
- Plan for failures

#### Maintenance
- Regular log rotation
- Clean up old job files
- Document job purposes
- Test job recovery

> 💡 **Pro Tips**:
> - Use `nice` for low-priority jobs
> - Set up job notifications
> - Implement job timeouts
> - Keep logs organized

## 📊 Quick Reference

### Common Commands
```bash
# Job Operations
systemctl status    # Check job status
systemctl start     # Start job
systemctl stop      # Stop job
systemctl restart   # Restart job

# Log Viewing
journalctl          # View logs
journalctl -f       # Follow logs
journalctl -u       # Unit logs

# Scheduling
crontab -e          # Edit schedule
crontab -l          # List schedule
```

### Monitoring Commands
```bash
# System monitoring
top                 # Process viewer
htop                # Enhanced top
ps aux              # Process status

# Log monitoring
tail -f            # Follow log file
grep -r "error"     # Search logs
```

---

✅ Use this guide as a reference for managing jobs and services in TrueNAS Scale. Always test commands in a safe environment first.
