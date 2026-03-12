# 🌐 Network Troubleshooting Guide #troubleshooting #networking #dns #firewall

A systematic approach to diagnosing and resolving network connectivity issues in your homelab. From basic connectivity checks to advanced firewall debugging.

## Table of Contents
1. [Connectivity Testing](#connectivity-testing)
2. [DNS Troubleshooting](#dns-troubleshooting)
3. [Firewall Debugging](#firewall-debugging)
4. [Port Checking](#port-checking)
5. [DHCP Issues](#dhcp-issues)
6. [VLAN Problems](#vlan-problems)
7. [Common Fixes](#common-fixes)
8. [Hardware Checks](#hardware-checks)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Connectivity Testing

### Basic Ping Test
```bash
# Test basic connectivity to a host
ping -c 4 8.8.8.8

# Continuous ping (stop with Ctrl+C)
ping 192.168.1.1

# Ping with specific interface
ping -I eth0 8.8.8.8

# Test without DNS resolution (IP only)
ping -c 4 1.1.1.1
```

### Trace Route to Target
```bash
# Show network path to destination
traceroute 8.8.8.8

# Use UDP instead of ICMP
traceroute -U 8.8.8.8

# Limit to 30 hops (default)
traceroute -m 30 google.com

# Verbose output with latency
traceroute -v 8.8.8.8
```

### MTR - Real-time Path Analysis
```bash
# Install mtr if needed
sudo apt-get install mtr

# Interactive mode - shows packet loss and latency per hop
mtr 8.8.8.8

# Report mode (20 cycles then exit)
mtr -r -c 20 8.8.8.8

# UDP instead of ICMP
mtr -u 8.8.8.8

# Show both IPv4 and IPv6
mtr -b 8.8.8.8
```

### Check Interface Status
```bash
# View all interfaces with IP addresses
ip addr show

# View specific interface
ip addr show eth0

# Get interface statistics
ip -s link show

# Monitor interface changes in real-time
watch -n 1 'ip addr show eth0'
```

## DNS Troubleshooting

### Check DNS Resolution
```bash
# Simple lookup
nslookup google.com

# Specific DNS server
nslookup google.com 8.8.8.8

# Reverse DNS lookup
nslookup 8.8.8.8

# All DNS records
dig ANY google.com
```

### Detailed DNS Query with dig
```bash
# Simple A record lookup
dig google.com

# Specific record type
dig google.com MX

# Query specific nameserver
dig @8.8.8.8 google.com

# Short output
dig +short google.com

# Trace DNS delegation chain
dig +trace google.com

# Show all query details
dig +noall +answer google.com

# Check TTL values
dig google.com | grep -A 1 "ANSWER SECTION"
```

### Check Local DNS Configuration
```bash
# View resolv.conf
cat /etc/resolv.conf

# Check systemd DNS resolver
systemd-resolve --status

# Query through systemd resolver
systemctl status systemd-resolved

# Manual DNS query through systemd
systemd-resolve google.com

# Flush systemd DNS cache
sudo systemd-resolve --flush-caches
```

### DNS Propagation Check
```bash
# Check all DNS servers for domain
for ns in 8.8.8.8 1.1.1.1 208.67.222.222; do
  echo "Testing with $ns:"
  dig @$ns myserver.com +short
done

# Monitor DNS changes (for testing)
watch -n 5 'dig myserver.com +short'
```

## Firewall Debugging

### iptables Investigation
```bash
# List all rules with line numbers
sudo iptables -L -n -v --line-numbers

# Show only INPUT chain
sudo iptables -L INPUT -n -v

# Show rules with packet counts
sudo iptables -L -n -v

# Display raw format
sudo iptables -L -n -v -x

# Check for NATing rules
sudo iptables -t nat -L -n -v

# Monitor firewall logs (if enabled)
sudo tail -f /var/log/kern.log | grep -i firewall
```

### UFW Debugging
```bash
# Show UFW status
sudo ufw status

# Verbose status with rule numbers
sudo ufw status verbose

# Show numbered rules (for deletion)
sudo ufw status numbered

# Test rule insertion
sudo ufw allow from 192.168.1.5 to any port 22

# Reload rules
sudo ufw reload

# Reset firewall (careful!)
sudo ufw reset
```

### Connection State Tracking
```bash
# View established connections
ss -tulpn | grep ESTABLISHED

# Monitor connections in real-time
watch -n 1 'ss -tulpn | grep ESTABLISHED'

# Count connections by state
ss -s

# Find connections to specific port
ss -tulpn | grep :8080

# View with PID info
sudo ss -tulpnp
```

## Port Checking

### ss Command (Modern Approach)
```bash
# Show all listening ports
sudo ss -tulpn

# Show only listening TCP ports
sudo ss -tln

# Show specific port
sudo ss -tulpn | grep 8080

# Show with process info
sudo ss -tulpnp | grep 8080

# Monitor changes
watch -n 1 'sudo ss -tulpn'
```

### netstat Command (Legacy)
```bash
# Show listening ports
sudo netstat -tulpn

# Show all established connections
sudo netstat -tulpn | grep ESTABLISHED

# Show specific port
sudo netstat -tulpn | grep :22

# Show with process info
sudo netstat -tulpn
```

### nmap Port Scanning
```bash
# Install nmap
sudo apt-get install nmap

# Scan local machine
nmap localhost

# Scan specific port
nmap -p 8080 localhost

# Scan port range
nmap -p 8000-9000 localhost

# Verbose output
nmap -v localhost

# Service version detection
nmap -sV localhost
```

### telnet/nc for Port Testing
```bash
# Test if port is open (timeout in 2 seconds)
timeout 2 bash -c '</dev/tcp/192.168.1.5/22' && echo "Port open" || echo "Port closed"

# Using nc
nc -zv 192.168.1.5 22

# Test multiple ports
nc -zv 192.168.1.5 22 80 443 8080
```

## DHCP Issues

### Check DHCP Configuration
```bash
# View DHCP client status
ip addr show

# Release current lease
sudo dhclient -r

# Request new lease
sudo dhclient

# Check DHCP details on interface
dhclient -v eth0

# View DHCP lease info
cat /var/lib/dhcp/dhclient.eth0.leases
```

### Monitor DHCP Traffic
```bash
# Install tcpdump if needed
sudo apt-get install tcpdump

# Capture DHCP packets
sudo tcpdump -i eth0 port 67 or port 68

# More detailed DHCP capture
sudo tcpdump -i eth0 -A -vv 'port 67 or port 68'
```

### Static IP Configuration
```bash
# View current config
cat /etc/netplan/00-installer-config.yaml

# Example static IP config
sudo cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.10/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF

# Apply changes
sudo netplan apply

# Verify
ip addr show
```

## VLAN Problems

### Check VLAN Configuration
```bash
# List VLAN interfaces
ip link show | grep vlan

# Create VLAN interface
sudo ip link add link eth0 name eth0.100 type vlan id 100

# Assign IP to VLAN
sudo ip addr add 192.168.100.10/24 dev eth0.100

# Bring up VLAN interface
sudo ip link set eth0.100 up

# Remove VLAN
sudo ip link del eth0.100
```

### Troubleshoot VLAN Traffic
```bash
# Check tagged traffic on physical interface
sudo tcpdump -i eth0 -e 'vlan'

# Monitor VLAN interface
watch -n 1 'ip -s link show eth0.100'

# Verify VLAN connectivity
ping -c 4 192.168.100.5 -I eth0.100
```

## Common Fixes

### Reset Network Interface
```bash
# Restart single interface
sudo ip link set eth0 down
sudo ip link set eth0 up

# Or using systemd
sudo systemctl restart networking

# Or for specific interface
sudo systemctl restart systemd-networkd
```

### Clear ARP Cache
```bash
# View ARP cache
arp -n

# Clear all ARP entries
sudo ip -s neigh flush all

# Clear specific entry
sudo arp -d 192.168.1.100
```

### Fix Temporary Network Issues
```bash
# Reload network configuration
sudo netplan apply

# Restart network service
sudo systemctl restart networking

# Check for errors
sudo netplan validate
```

## Hardware Checks

### Physical Interface Status
```bash
# Check ethtool for interface details
sudo apt-get install ethtool

# View interface info
sudo ethtool eth0

# Show link status
sudo ethtool eth0 | grep "Link detected"

# View speed/duplex
sudo ethtool eth0 | grep Speed

# Test interface
sudo ethtool -t eth0
```

### Check Cable and Connections
```bash
# Monitor for link flaps
sudo ip monitor link

# Watch for carrier changes
watch -n 1 'cat /sys/class/net/eth0/carrier'

# Check interface statistics for errors
ethtool -S eth0 | grep -i error
```

## Troubleshooting

### Issue: Can't ping anything
**Steps:**
1. Check interface is up: `ip link show`
2. Check IP assignment: `ip addr show`
3. Check default route: `ip route show`
4. Verify physical cable is connected
5. Check firewall rules: `sudo ufw status`

### Issue: DNS not resolving
**Steps:**
1. Check resolv.conf: `cat /etc/resolv.conf`
2. Test DNS directly: `dig @8.8.8.8 google.com`
3. Check systemd-resolved: `systemctl status systemd-resolved`
4. Flush cache: `sudo systemd-resolve --flush-caches`
5. Restart resolver: `sudo systemctl restart systemd-resolved`

### Issue: Port not accessible
**Steps:**
1. Verify service is running: `sudo ss -tulpn | grep :PORT`
2. Check firewall allows it: `sudo ufw status verbose`
3. Test locally: `telnet localhost PORT`
4. Check service binding: Check if service listening on all interfaces
5. Review service logs: `sudo journalctl -u servicename -n 50`

### Issue: High latency or packet loss
**Steps:**
1. Use mtr to identify slow hop: `mtr 8.8.8.8`
2. Check interface errors: `ethtool -S eth0 | grep -i error`
3. Monitor CPU/memory: `top` or `htop`
4. Check for network saturation: `iftop` or `nethogs`

## Best Practices

- Always test from source and destination
- Document your network topology and IP scheme
- Use DNS names instead of IPs when possible
- Monitor network metrics regularly
- Keep firewall rules documented
- Test connectivity in both directions
- Use systematic approach: hardware → network layer → DNS → service layer

---

✅ Network troubleshooting guide complete - use systematic testing methodology for faster resolution
