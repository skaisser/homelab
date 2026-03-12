# 📖 Linux Command Quick Reference #linux #commands #reference

A comprehensive quick reference for essential Linux commands, organized by category.

## 📋 Table of Contents
- [File Operations](#file-operations)
- [System Information](#system-information)
- [Process Management](#process-management)
- [Network Commands](#network-commands)
- [Package Management](#package-management)
- [User Management](#user-management)
- [Permission Management](#permission-management)

## 📁 File Operations

### Basic File Commands
```bash
ls          # List files and directories
ls -la      # List with details and hidden files
pwd         # Print working directory
cd dir      # Change directory
mkdir dir   # Create directory
rmdir dir   # Remove empty directory
rm file     # Remove file
rm -r dir   # Remove directory and contents
cp src dst  # Copy file/directory
mv src dst  # Move/rename file/directory
```

### File Viewing
```bash
cat file    # View file content
less file   # Page through file
head file   # View first 10 lines
tail file   # View last 10 lines
tail -f file # Follow file changes
grep pattern file # Search in file
```

### File Permissions
```bash
chmod 755 file  # Change permissions
chown user file # Change owner
chgrp group file # Change group
```

## 💻 System Information

### System Status
```bash
uname -a    # System information
uptime      # System uptime
date        # Current date/time
cal         # Calendar
df -h       # Disk usage
free -h     # Memory usage
```

### Hardware Info
```bash
lscpu       # CPU information
lsusb       # USB devices
lspci       # PCI devices
dmidecode   # Hardware info
sensors     # Temperature sensors
```

## 🔄 Process Management

### Process Control
```bash
ps aux      # List all processes
top         # Process monitor
htop        # Enhanced process monitor
kill pid    # Kill process
killall name # Kill all matching processes
```

### Background Jobs
```bash
command &   # Run in background
jobs        # List background jobs
fg         # Bring to foreground
bg         # Send to background
nohup command # Run immune to hangups
```

## 🌐 Network Commands

### Connectivity
```bash
ping host   # Test connectivity
traceroute host # Trace route
dig domain  # DNS lookup
nslookup domain # Name server lookup
whois domain # Domain information
```

### Network Config
```bash
ip addr     # Show IP addresses
ip route    # Show routing table
netstat -tuln # Show ports in use
ss -tuln    # Socket statistics
```

## 📦 Package Management

### APT (Debian/Ubuntu)
```bash
apt update  # Update package list
apt upgrade # Upgrade packages
apt install pkg # Install package
apt remove pkg # Remove package
apt search pkg # Search packages
```

### DNF (RHEL/Fedora)
```bash
dnf update  # Update packages
dnf install pkg # Install package
dnf remove pkg # Remove package
dnf search pkg # Search packages
```

## 👥 User Management

### User Commands
```bash
whoami      # Current user
id          # User/group IDs
useradd user # Create user
userdel user # Delete user
passwd user # Change password
su user     # Switch user
sudo command # Run as root
```

### Group Management
```bash
groups      # Show groups
groupadd grp # Create group
groupdel grp # Delete group
usermod -aG grp user # Add user to group
```

## 🔒 Permission Management

### File Permissions
```bash
chmod       # Change mode
  u+rwx     # User: add read/write/execute
  g+rx      # Group: add read/execute
  o-rwx     # Others: remove all
  a+r       # All: add read
  755       # User:rwx Group:rx Others:rx
```

### Special Permissions
```bash
chmod       # Special modes
  4000      # Set UID
  2000      # Set GID
  1000      # Sticky bit
```

## 💡 Tips

1. Use tab completion to save typing
2. Use up/down arrows for command history
3. Use Ctrl+R to search command history
4. Use Ctrl+L or `clear` to clear screen
5. Use `man` or `--help` for help

## 🔍 Finding Help

```bash
man command # Manual pages
info command # GNU info pages
command --help # Quick help
apropos keyword # Search man pages
```

Remember:
- Commands are case-sensitive
- Most commands have multiple options
- Use `-h` or `--help` when unsure
- Practice in a safe environment first
