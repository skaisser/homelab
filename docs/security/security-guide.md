# 🔒 Linux Security Guide #security #linux #hardening #firewall

A comprehensive guide to securing Linux systems and implementing best security practices.

## 📋 Table of Contents
- [User Management](#user-management)
- [System Hardening](#system-hardening)
- [Firewall Configuration](#firewall-configuration)
- [Security Auditing](#security-auditing)
- [Monitoring](#monitoring)

## 👥 User Management

### Password Policies
```bash
# Set password complexity
sudo nano /etc/security/pwquality.conf

# Set password expiration
sudo chage -M 90 username  # Max days
sudo chage -W 7 username   # Warning days
```

### SSH Hardening
```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Key settings to modify:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Protocol 2
```

## 🛡️ System Hardening

### Update Management
```bash
# Enable automatic security updates (Ubuntu)
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades

# Check update status
sudo unattended-upgrades --dry-run
```

### Service Hardening
```bash
# List running services
systemctl list-units --type=service

# Disable unnecessary services
sudo systemctl disable service_name
sudo systemctl mask service_name
```

## 🧱 Firewall Configuration

### UFW (Uncomplicated Firewall)
```bash
# Enable UFW
sudo ufw enable

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow specific services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Allow specific ports
sudo ufw allow 8080/tcp
```

### IPTables
```bash
# Basic rules
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -P INPUT DROP

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

## 🔍 Security Auditing

### System Auditing
```bash
# Install auditd
sudo apt install auditd

# Configure audit rules
sudo nano /etc/audit/rules.d/audit.rules

# Check audit logs
sudo ausearch -k auth
```

### File Integrity
```bash
# Install AIDE
sudo apt install aide

# Initialize database
sudo aideinit

# Check for changes
sudo aide --check
```

## 📊 Monitoring

### Log Monitoring
```bash
# View auth logs
sudo tail -f /var/log/auth.log

# View system logs
sudo journalctl -f

# Monitor failed login attempts
sudo grep \"Failed password\" /var/log/auth.log
```

### Resource Monitoring
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor system resources
htop

# Monitor disk I/O
sudo iotop

# Monitor network usage
sudo nethogs
```

## 🔒 Security Best Practices

1. **Regular Updates**
   - Keep system and packages updated
   - Enable automatic security updates
   - Monitor security advisories

2. **Access Control**
   - Use strong passwords
   - Implement 2FA where possible
   - Regular access audits
   - Principle of least privilege

3. **Network Security**
   - Configure firewall rules
   - Use VPN for remote access
   - Segment networks
   - Monitor network traffic

4. **Backup Strategy**
   - Regular system backups
   - Secure backup storage
   - Test recovery procedures
   - Document backup processes

5. **Monitoring and Auditing**
   - Enable system logging
   - Regular security audits
   - Monitor system resources
   - Set up alerts for suspicious activity

## 📚 Additional Resources

- [Linux Security Documentation](https://www.kernel.org/doc/html/latest/security/index.html)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Guidelines](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-123.pdf)

> 💡 **Note**: Always test security changes in a safe environment first and ensure you have a way to revert changes if needed.
