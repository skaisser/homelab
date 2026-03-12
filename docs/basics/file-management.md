# 📁 File Management – Linux Commands #files #tar #permissions #linux

A comprehensive guide for managing files and directories in Linux systems. Organized by task type with practical examples and best practices.

## 📋 Table of Contents
- [Archive Management](#-tar-archives)
- [File Cleanup](#-file-cleanup)
- [File Operations](#-moving--copying)
- [Navigation & Permissions](#-navigation--permissions)
- [Special Utilities](#-special-utilities)
- [Advanced Tips](#-tips)

---

## 📦 Tar Archives

### 🗜️ Compress Files and Folders
```bash
# Basic tar.gz compression
tar czvf archive.tar.gz folder/

# Exclude specific files/patterns
tar czvf archive.tar.gz folder/ --exclude='*.tmp' --exclude='cache'

# Preserve permissions
tar czpvf archive.tar.gz folder/
```
> 💡 **Options Explained**:
> - `c`: Create new archive
> - `z`: Compress using gzip
> - `v`: Verbose output
> - `f`: Specify archive name
> - `p`: Preserve permissions

### 📂 Extract Archives
```bash
# Extract to current directory
tar xzvf archive.tar.gz

# Extract to specific directory
mkdir -p /path-to-destination
tar xzvf archive.tar.gz -C /path-to-destination

# List contents without extracting
tar tzvf archive.tar.gz
```

## 📦 Zip Archives

### 🗜️ Working with Zip Files
```bash
# Create zip archive
zip -r archive.zip folder/

# Create encrypted zip
zip -er archive.zip folder/

# Add files to existing zip
zip -u archive.zip newfile.txt

# Extract zip archive
unzip archive.zip

# List contents without extracting
unzip -l archive.zip
```

## 🧹 File Cleanup

### 🗑️ Find and Manage Large Files
```bash
# Find files over 100MB and prompt before deletion
find . -type f -size +100M -exec rm -i {} \;

# List files by size (largest first)
du -h | sort -rh | head -n 10

# Find files not accessed in 30 days
find . -type f -atime +30
```

### 🔍 Find Files by Time
```bash
# Modified in last 3 days
find . -type f -mtime -3

# Modified between 7 and 30 days ago
find . -type f -mtime +7 -mtime -30

# Changed in the last hour
find . -type f -cmin -60
```

### 🧹 Cleanup Operations
```bash
# Remove empty directories
find . -type d -empty -delete

# Remove empty files
find . -type f -empty -delete

# Remove files by pattern
find . -name "*.tmp" -delete
```

## 🚚 Moving & Copying

### 📤 Copy Operations
```bash
# Copy with progress
rsync -ah --progress source/ destination/

# Copy preserving attributes
cp -rp source/ destination/

# Copy only newer files
cp -u source/* destination/
```

### 📥 Move Operations
```bash
# Move with backup
mv -b source/ destination/

# Move without overwriting
mv -n source/ destination/

# Interactive move
mv -i source/ destination/
```

## 🧭 Navigation & Permissions

### 🔍 File Information
```bash
# Disk usage by directory
du -sh */

# Detailed listing with human-readable sizes
ls -lh

# Show hidden files
ls -la

# Sort by size
ls -lS
```

### 🔐 Permission Management
```bash
# Change owner and group
chown -R user:group directory/

# Common permission patterns
chmod 755 file  # rwxr-xr-x
chmod 644 file  # rw-r--r--
chmod 700 file  # rwx------

# Add execute permission
chmod +x script.sh
```

## 🧪 Special Utilities

### 🔁 File Comparison
```bash
# Compare files
diff -u file1.txt file2.txt

# Three-way merge
diff3 mine.txt original.txt yours.txt

# Binary file comparison
cmp file1 file2
```

### 📊 File Analysis
```bash
# Count lines, words, characters
wc -l file.txt     # lines only
wc -w file.txt     # words only
wc -m file.txt     # characters

# File type information
file filename
```

### 🧼 File Naming
```bash
# Remove special characters
rename 's/[^a-zA-Z0-9._-]//g' *

# Convert to lowercase
rename 'y/A-Z/a-z/' *

# Add prefix to files
rename 's/^/prefix-/' *
```

## 💡 Tips

### 🔄 Backup Best Practices
- Use `rsync` for efficient incremental backups:
  ```bash
  rsync -av --delete source/ destination/
  ```

### ⚡ Performance Tips
- Use `nice` for CPU-intensive operations:
  ```bash
  nice -n 19 tar czf archive.tar.gz large-directory/
  ```

### 🔒 Security Best Practices
- Always verify destructive commands
- Use `-i` flag for interactive operations
- Keep regular backups of important data
- Set appropriate file permissions

### 🤖 Automation
- Create aliases for common operations
- Use `cron` for scheduled tasks
- Consider using `inotify` for file monitoring

> 🎯 **Remember**: Always test commands on a small sample before running them on large datasets!
