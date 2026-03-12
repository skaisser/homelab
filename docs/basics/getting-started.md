# 🚀 Getting Started with Linux #linux #basics #tutorial

A beginner-friendly introduction to Linux system administration and command line usage.

## 📋 Table of Contents
- [Basic Concepts](#basic-concepts)
- [Essential Commands](#essential-commands)
- [System Navigation](#system-navigation)
- [Next Steps](#next-steps)

## 🔰 Basic Concepts

### What is Linux?
Linux is a free and open-source operating system kernel that forms the foundation of many modern operating systems (distributions or "distros").

### Common Distributions
- Ubuntu - User-friendly, great for beginners
- Debian - Stable, great for servers
- CentOS/Rocky Linux - Enterprise-grade
- Arch Linux - Advanced users, rolling release

## 💻 Essential Commands

### System Information
```bash
# Check system information
uname -a          # System and kernel info
lsb_release -a    # Distribution info
df -h             # Disk usage
free -h           # Memory usage
top               # Process monitor
```

### File System Navigation
```bash
pwd               # Present working directory
ls               # List files and directories
cd directory     # Change directory
mkdir dirname    # Create directory
rm filename      # Remove file
cp source dest   # Copy files
mv source dest   # Move/rename files
```

### File Viewing and Editing
```bash
cat filename     # View file contents
less filename    # Page through file
nano filename    # Simple text editor
vim filename     # Advanced text editor
```

## 🗺️ System Navigation

### Directory Structure
- `/` - Root directory
- `/home` - User home directories
- `/etc` - System configuration
- `/var` - Variable data (logs, etc.)
- `/usr` - User programs and data
- `/bin`, `/sbin` - Essential commands
- `/opt` - Optional software
- `/tmp` - Temporary files

### Important Configuration Files
- `/etc/fstab` - Filesystem table
- `/etc/passwd` - User accounts
- `/etc/hosts` - Host name resolution
- `/etc/ssh/sshd_config` - SSH configuration

## 📚 Next Steps

After mastering these basics, explore:
1. [File Management Guide](file-management.md) for advanced file operations
2. [Network Testing Guide](network-testing.md) for network management
3. [Docker Guide](docker-guide.md) for containerization
4. [ZFS Storage Guide](zfs-storage.md) for storage management

## 💡 Pro Tips

1. Use tab completion to save time
2. Learn keyboard shortcuts
3. Create aliases for common commands
4. Keep a cheat sheet handy
5. Practice in a safe environment

## 🔍 Troubleshooting Basics

### Common Commands
```bash
dmesg           # Kernel messages
journalctl      # System logs
ps aux          # Process list
netstat -tuln   # Network connections
```

### Getting Help
- Use `man command` for manual pages
- Use `command --help` for quick help
- Use `info command` for detailed documentation

📚 Check our comprehensive [Command Reference](command-reference.md) for a quick overview of all essential Linux commands.

Remember: The best way to learn is by doing. Start with simple commands and gradually work your way up to more complex operations.
