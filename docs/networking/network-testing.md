# 📶 Network Speed Testing Guide #network #performance #iperf #troubleshooting

Comprehensive guide for testing network performance in various scenarios using different tools.

## 📋 Table of Contents
- [iPerf3 Testing](#iperf3-testing)
- [Alternative Tools](#alternative-tools)
- [Performance Analysis](#performance-analysis)
- [Troubleshooting](#troubleshooting)

## 📊 iPerf3 Testing

### Docker-based Testing

#### Server Setup
```bash
# Basic server
docker run -d --rm \
    -p 5201:5201 \
    --name=iperf3-server \
    networkstatic/iperf3 -s

# Server with JSON output
docker run -d --rm \
    -p 5201:5201 \
    --name=iperf3-server \
    networkstatic/iperf3 -s -J
```

#### Client Testing
```bash
# Basic speed test
docker run -it --rm \
    --network=host \
    networkstatic/iperf3 -c 10.0.0.3

# Detailed test with options
docker run -it --rm \
    --network=host \
    networkstatic/iperf3 \
    -c 10.0.0.3 \
    -p 5201 \
    -t 30 \
    -i 1 \
    -w 128K \
    -P 4 \
    -R
```
> Options explained:
> - `-t 30`: Run for 30 seconds
> - `-i 1`: Report interval of 1 second
> - `-w 128K`: Window size of 128KB
> - `-P 4`: Use 4 parallel streams
> - `-R`: Reverse mode (server to client)

### Native iPerf3 Installation

```bash
# Install iPerf3
apt-get update && apt-get install -y iperf3

# Start server
iperf3 -s

# Run client test
iperf3 -c server_ip
```

## 📊 Alternative Tools

### Speed Test CLI
```bash
# Install speedtest-cli
pip install speedtest-cli

# Run basic test
speedtest-cli

# Get raw values in CSV
speedtest-cli --csv
```

### Fast.com CLI
```bash
# Install fast-cli
npm install -g fast-cli

# Run test
fast
```

### Network Performance Testing
```bash
# Basic ping test
ping -c 5 target_ip

# MTR (My TraceRoute) test
mtr -n target_ip

# TCP connection test
nc -vz target_ip port
```

## 📏 Performance Analysis

### Network Quality Metrics
```bash
# Check packet loss
ping -f -c 1000 target_ip | grep 'packet loss'

# Check latency distribution
ping -c 100 target_ip | awk '{print $7}' | cut -d '=' -f 2 | sort -n | awk '{a[i++]=$1;} END{print "Min="a[0]", Avg="a[int(i/2)]", Max="a[i-1]}'}

# Monitor bandwidth usage
iftop -i eth0
```

### Network Interface Stats
```bash
# View interface statistics
ip -s link show eth0

# Monitor network traffic
netstat -i

# Detailed network statistics
ss -s
```

## 🔧 Troubleshooting

### Common Issues
1. **Poor Performance**
   ```bash
   # Check interface speed
   ethtool eth0
   
   # Check for errors
   netstat -i | grep -i error
   ```

2. **Connection Issues**
   ```bash
   # DNS resolution
nslookup target_domain

   # Route tracing
traceroute target_ip
   ```

### Best Practices
- Run tests during off-peak hours
- Test both TCP and UDP performance
- Monitor system resources during tests
- Document baseline performance
- Test with different packet sizes

> 💡 **Pro Tips**:
> - Use `-b` flag in iperf3 to set bandwidth limits
> - Test both IPv4 and IPv6 if available
> - Consider using different protocols (TCP/UDP)
> - Monitor CPU usage during tests
> - Save results for historical comparison
