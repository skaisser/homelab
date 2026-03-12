# 🗃️ Linux File Transfer Guide

Comprehensive guide for efficient file transfers across different systems and protocols, optimized for performance and reliability.

## 📋 Table of Contents
- [Rsync Operations](#-rsync-efficient-file-sync)
- [Rclone Cloud Sync](#️-rclone-cloud-and-remote-sync)
- [SCP Transfers](#-scp-secure-copy)
- [Performance Tips](#-performance-optimization)
- [Troubleshooting](#-troubleshooting)

## 📁 Rsync (Efficient File Sync) #rsync

### Basic Remote Transfers
```bash
# Basic remote transfer with progress
rsync -avzP /source/ user@remote:/dest/

# Transfer with custom SSH port
rsync -avzP -e 'ssh -p 2222' /source/ user@remote:/dest/

# Transfer with bandwidth limit (1MB/s)
rsync -avzP --bwlimit=1000 /source/ user@remote:/dest/
```

### Advanced Rsync Features
```bash
# Sync with deletion (mirror)
rsync -avzP --delete /source/ /dest/

# Partial/Resume Support
rsync -avzP --partial-dir=.rsync-partial /source/ /dest/

# Include/Exclude Patterns
rsync -avzP \
  --exclude='*.tmp' \
  --exclude='cache/' \
  --include='important/**' \
  /source/ /dest/
```

### High-Performance Transfers
```bash
# Maximum Performance (Local Network)
rsync -aHAX \
  --numeric-ids \
  --info=progress2 \
  --no-compress \
  --delete \
  /source/ /dest/

# With Logging and Source Cleanup
rsync -aHAX \
  --remove-source-files \
  --log-file=/var/log/rsync.log \
  /source/ /dest/ 2>&1
```

## ☁️ Rclone (Cloud and Remote Sync)

### Configuration Examples

#### SFTP Setup
```ini
[remote-sftp]
type = sftp
host = server.example.com
user = username
key_file = ~/.ssh/id_rsa
shell_type = unix
md5sum_command = md5sum
sha1sum_command = sha1sum
use_insecure_cipher = false # Enable for legacy systems
```

> **Security Notice**: Replace placeholder values (`your_access_key`, `your_secret_key`) with your actual credentials. Never commit real keys to version control — use `rclone config` to store them securely.

#### S3-Compatible Storage
```ini
[s3-storage]
type = s3
provider = Minio
access_key_id = your_access_key
secret_access_key = your_secret_key
region = other-v2-signature
endpoint = https://s3.example.com
location_constraint = region-name
acl = private
server_side_encryption = AES256
```

### Optimized Transfer Commands
```bash
# High-Performance Copy
rclone copy source:path dest:path \
  --transfers=16 \
  --checkers=32 \
  --multi-thread-streams=16 \
  --buffer-size=64M \
  --use-mmap \
  --stats=1s \
  --progress \
  --fast-list

# Sync with Deletion
rclone sync source:path dest:path \
  --create-empty-src-dirs \
  --track-renames \
  --delete-during \
  --transfers=8
```

### Rclone Performance Tips
- Adjust `--buffer-size` based on available RAM
- Use `--transfers` based on CPU cores and bandwidth
- Enable `--use-mmap` for better memory usage
- Use `--fast-list` for directories with many files

## 📡 SCP (Secure Copy)

### Basic Operations
```bash
# Copy directory with compression
scp -Crp /local/dir/ user@remote:/dest/

# Copy using specific identity file
scp -i ~/.ssh/special_key file.txt user@remote:/dest/

# Copy with bandwidth limit (1MB/s)
scp -l 1000 file.txt user@remote:/dest/
```

### Batch Transfers
```bash
# Copy multiple files
scp file1.txt file2.txt user@remote:/dest/

# Using wildcards
scp /source/*.{jpg,png} user@remote:/dest/

# Recursive copy with specific permissions
scp -rp -v /source/ user@remote:/dest/
```

## 🏑 Performance Optimization

### Network Tuning
```bash
# Set TCP window size
sysctl -w net.core.wmem_max=16777216
sysctl -w net.core.rmem_max=16777216

# Enable BBR congestion control
sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr
```

### Monitoring Transfer Speed
```bash
# Monitor network usage
iftop -i eth0

# Monitor disk I/O
iotop -oPa

# View transfer progress
watch -n1 'df -h'
```

## 🔧 Troubleshooting

### Common Issues
1. **Slow Transfers**
   ```bash
   # Test network speed
   iperf3 -c server_ip
   
   # Check disk speed
   dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync
   ```

2. **Connection Drops**
   ```bash
   # Keep SSH connection alive
   ssh -o ServerAliveInterval=60 user@remote
   
   # Use mosh for unstable connections
   mosh user@remote
   ```

### Best Practices
- Always use `screen` or `tmux` for long transfers
- Test transfers with small datasets first
- Monitor system resources during transfers
- Keep logs for important transfers
- Use checksums for verification

### Verification Commands
```bash
# Generate checksums
sha256sum * > checksums.txt

# Verify transfers
rsync -avzP --checksum /source/ /dest/

# Compare directories
diff -r /source/ /dest/
```

> 💡 **Pro Tips**:
> - Use `ionice` for background transfers
> - Consider using `aria2c` for parallel downloads
> - Implement retry mechanisms for unreliable connections
> - Monitor disk space before large transfers
