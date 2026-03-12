# 📊 Linux System Monitoring Guide #monitoring #performance #logs #metrics

A comprehensive guide to monitoring Linux systems, services, and resources.

## 📋 Table of Contents
- [System Metrics](#system-metrics)
- [Log Management](#log-management)
- [Monitoring Tools](#monitoring-tools)
- [Alert Configuration](#alert-configuration)
- [Visualization](#visualization)

## 📈 System Metrics

### Resource Usage
```bash
# CPU usage
top
htop
mpstat 1

# Memory usage
free -h
vmstat 1
slabtop

# Disk usage
df -h
du -sh /*
iotop
```

### Process Monitoring
```bash
# Process list
ps aux
pstree

# Process details
pidstat 1
strace -p PID
lsof -p PID
```

## 📝 Log Management

### System Logs
```bash
# View system logs
journalctl
tail -f /var/log/syslog

# View auth logs
tail -f /var/log/auth.log

# View specific service logs
journalctl -u service_name
```

### Log Aggregation
```bash
# Install rsyslog
sudo apt install rsyslog

# Configure remote logging
sudo nano /etc/rsyslog.conf

# Rotate logs
sudo logrotate /etc/logrotate.conf
```

## 🛠 Monitoring Tools

### Prometheus Setup
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

### Node Exporter
```bash
# Install node exporter
wget https://github.com/prometheus/node_exporter/releases/download/v*/node_exporter-*-amd64.tar.gz
tar xvf node_exporter-*-amd64.tar.gz
cd node_exporter-*

# Run node exporter
./node_exporter
```

> **Security Notice**: The credentials shown below are placeholders. Never use default passwords in production. Store sensitive values in environment variables or a secrets manager.

### Grafana Configuration
```ini
[server]
http_addr = localhost
http_port = 3000

[security]
admin_user = admin
admin_password = secure_password
```

## ⚡ Alert Configuration

### Prometheus Alerting
```yaml
groups:
- name: example
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: High CPU usage

  - alert: LowDiskSpace
    expr: node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"} * 100 < 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Low disk space
```

> **Security Notice**: Use environment variables or a secrets manager for SMTP credentials. Never commit real passwords to version control.

### Email Alerts
```yaml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'username'
  smtp_auth_password: 'password'

route:
  group_by: ['alertname']
  receiver: 'email-notifications'

receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@example.com'
```

## 📊 Visualization

### Grafana Dashboards
1. **System Overview**
   - CPU Usage
   - Memory Usage
   - Disk I/O
   - Network Traffic

2. **Application Metrics**
   - Request Rate
   - Error Rate
   - Response Time
   - Active Users

3. **Log Analytics**
   - Error Frequency
   - Log Patterns
   - Security Events
   - Performance Issues

## 💡 Best Practices

1. **Data Collection**
   - Collect only necessary metrics
   - Set appropriate retention periods
   - Use efficient storage formats
   - Implement data aggregation

2. **Alert Configuration**
   - Set meaningful thresholds
   - Avoid alert fatigue
   - Use proper alert routing
   - Document alert responses

3. **Performance Impact**
   - Monitor the monitors
   - Optimize collection intervals
   - Use efficient logging
   - Clean up old data

4. **Security Considerations**
   - Secure monitoring endpoints
   - Encrypt sensitive data
   - Control access to dashboards
   - Audit monitoring access

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Linux Performance](http://www.brendangregg.com/linuxperf.html)

> 💡 **Pro Tip**: Start with basic system metrics and gradually add more sophisticated monitoring as needed. Focus on metrics that directly impact your service quality.
