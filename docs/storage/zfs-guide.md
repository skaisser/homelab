# 🗄️ ZFS Storage Management Guide #zfs #storage #filesystem #performance #snapshots

Comprehensive guide for managing ZFS storage systems, focusing on TrueNAS Scale environments but applicable to any ZFS setup.

## 📋 Table of Contents
- [Pool Management](#-pool-management)
- [Dataset Operations](#-dataset-operations)
- [Snapshot Management](#-snapshot-management)
- [Performance Tuning](#-performance-tuning)
- [Maintenance](#-maintenance--monitoring)
- [Troubleshooting](#-troubleshooting)

## 🔧 Pool Management

### Pool Creation and Status
```bash
# Create a basic pool
zpool create tank mirror sda sdb

# Create a RAIDZ2 pool
zpool create datapool raidz2 sda sdb sdc sdd sde sdf

# Show pool status and health
zpool status
zpool list

# Detailed pool information
zpool get all datapool
```

### Pool Maintenance
```bash
# Start pool scrub
zpool scrub datapool

# Check scrub progress
zpool status datapool

# Clear pool errors
zpool clear datapool

# Export/Import pool
zpool export datapool
zpool import -d /dev/disk/by-id datapool
```

### Performance Monitoring
```bash
# Real-time I/O statistics
zpool iostat -v 2

# Extended stats
zpool iostat -vy 5

# Check pool capacity
zpool list -v
```

## 📂 Dataset Operations

### Basic Dataset Management
```bash
# Create dataset with specific properties
zfs create -o compression=lz4 \
          -o atime=off \
          -o recordsize=1M \
          datapool/dataset1

# List datasets and properties
zfs list -o name,used,avail,compression,mountpoint

# Get all properties
zfs get all datapool/dataset1
```

### Dataset Properties
```bash
# Set multiple properties
zfs set compression=lz4 datapool/dataset1
zfs set atime=off datapool/dataset1
zfs set recordsize=1M datapool/dataset1

# Inheritance
zfs inherit compression datapool/dataset1

# Quotas and Reservations
zfs set quota=100G datapool/dataset1
zfs set reservation=50G datapool/dataset1
```

## 📸 Snapshot Management

### Snapshot Operations
```bash
# Create timestamped snapshot
zfs snapshot datapool/dataset1@$(date +%Y-%m-%d_%H-%M)

# List snapshots
zfs list -t snapshot -o name,creation,used,referenced

# Recursive snapshots
zfs snapshot -r datapool@backup-$(date +%Y-%m-%d)

# Remove old snapshots
zfs list -t snapshot -o name -s creation | head -n 5 | xargs -n 1 zfs destroy
```

### Snapshot Replication
```bash
# Send full backup
zfs send datapool/dataset1@snap1 | zfs receive backup/dataset1

# FULL replication of the snapshot called “migrate”, this assumes youve created already a snapshot called migrate recursive.
# (-R = include children & properties)
# (pv is optional, just shows speed/progress)
# (-F = roll back target if it exists)
# (-d = strip the leading path so datasets land under pool "big")
zfs send -R cache/immich@migrate | pv | zfs receive -vFd big

# Send incremental backup
zfs send -i datapool/dataset1@snap1 datapool/dataset1@snap2 | \
zfs receive backup/dataset1

# Resume interrupted transfer
zfs send -t <resume-token> | zfs receive -s backup/dataset1
```

## 🏑 Performance Tuning

### Memory Management
```bash
# Set ARC size (Adaptive Replacement Cache)
echo "options zfs zfs_arc_max=8589934592" > /etc/modprobe.d/zfs.conf

# Monitor ARC stats
arc_summary
arcstat -f time,read,hit%,miss%,miss 1
```

### Dataset Optimization
```bash
# For general purpose
zfs set compression=lz4 datapool/dataset1
zfs set atime=off datapool/dataset1

# For databases
zfs set recordsize=8K datapool/database
zfs set logbias=throughput datapool/database

# For VMs
zfs set recordsize=64K datapool/vms
zfs set sync=disabled datapool/vms
```

## 📊 Maintenance & Monitoring

### Health Monitoring
```bash
# Check pool health
zpool status -v

# View error logs
zpool events

# Check device errors
zpool status -v | grep -A1 errors:
```

### Space Management
```bash
# Show space usage
zfs list -o name,used,avail,referenced,compressratio

# Find large datasets
zfs list -o name,used -s used

# Show snapshot space usage
zfs list -t snapshot -o name,used,referenced
```

## 🔧 Troubleshooting

### Common Issues

1. **Pool Degraded**
   ```bash
   # Check status
   zpool status -v

   # Replace failed disk
   zpool replace datapool old_disk new_disk
   ```

2. **Performance Issues**
   ```bash
   # Check fragmentation
   zpool list -v

   # Monitor I/O
   zpool iostat -v 1
   ```

3. **Space Problems**
   ```bash
   # Find space hogs
   zfs list -o name,used,referenced -s used

   # Clean old snapshots
   zfs list -t snapshot -o name,used -s used
   ```

### Best Practices

#### Performance
- Use mirror vdevs for better performance
- Enable compression by default (lz4)
- Adjust recordsize based on workload
- Monitor and tune ARC size

#### Reliability
- Regular scrubs (weekly/monthly)
- Maintain backup snapshots
- Use ECC memory when possible
- Keep pools below 80% capacity

#### Maintenance
- Document pool configurations
- Keep spare disks available
- Monitor SMART attributes
- Regular backup testing

> 💡 **Pro Tips**:
> - Use `ashift=12` for modern drives
> - Consider L2ARC for read-heavy workloads
> - Use SLOG devices for sync writes
> - Monitor system memory for dedup

## 📊 Quick Reference

### Common Commands
```bash
# Pool operations
zpool status    # Check pool status
zpool scrub     # Start scrub
zpool import    # Import pool
zpool export    # Export pool

# Dataset operations
zfs list       # List datasets
zfs create     # Create dataset
zfs destroy    # Remove dataset
zfs set        # Set properties

# Snapshot operations
zfs snapshot   # Create snapshot
zfs rollback   # Restore snapshot
zfs send       # Send snapshot
zfs receive    # Receive snapshot
```

### Monitoring Commands
```bash
# Performance monitoring
arcstat        # ARC statistics
zpool iostat   # I/O statistics
zpool events   # Event logs

# Space monitoring
zfs list       # Space usage
zpool list     # Pool capacity
```

---

✅ This guide serves as a comprehensive reference for ZFS storage management. Always test commands in a safe environment first.
