# 📊 Centralized Logging Guide #monitoring #logging #elk #loki #syslog

Centralized logging aggregates logs from all your homelab devices and services into a single location. Instead of SSH-ing into each machine to debug issues, you can search and correlate logs across your entire infrastructure. This guide covers setting up a lightweight centralized logging stack suitable for homelabs: rsyslog forwarding, Loki for log storage, Promtail for log collection, and Grafana for visualization.

## Table of Contents

- [Why Centralized Logging](#why-centralized-logging)
- [Architecture Overview](#architecture-overview)
- [rsyslog Forwarding Setup](#rsyslog-forwarding-setup)
- [Loki + Promtail + Grafana Stack](#loki--promtail--grafana-stack)
- [Docker Compose Deployment](#docker-compose-deployment)
- [Log Retention Policies](#log-retention-policies)
- [Filtering and Parsing Logs](#filtering-and-parsing-logs)
- [Viewing Logs in Grafana](#viewing-logs-in-grafana)
- [journalctl Tips](#journalctl-tips)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Why Centralized Logging

Without centralized logging, troubleshooting multi-host issues is tedious:
- Service A on host1 calls Service B on host2, which fails
- You must SSH into each host and grep individual log files
- Correlation across services becomes a manual detective job

With centralized logging:
- All logs stream to one place
- Search and filter across services instantly
- Correlate events across your homelab
- Historical data retained and searchable
- Alerts on log patterns (high error rates, specific keywords)

## Architecture Overview

A typical homelab logging stack:
- **rsyslog/Promtail agents** run on each server and forward logs to
- **Loki**, which stores logs with labels and metadata
- **Grafana** queries Loki and displays logs with dashboards
- Optional: **Prometheus** scrapes Loki metrics for monitoring the logging system itself

This is lightweight enough for small homelabs (few servers, modest storage).

## rsyslog Forwarding Setup

On each client server, configure rsyslog to forward logs to a central syslog server.

Install rsyslog (usually pre-installed on Linux):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Update package list
sudo apt-get update

# Install rsyslog if not present
sudo apt-get install -y rsyslog
```

Create a forwarding rule in `/etc/rsyslog.d/99-forward.conf`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configure rsyslog to forward to a central server
# Replace LOGSERVER_IP with your Loki/syslog server IP

cat << 'EOF' | sudo tee /etc/rsyslog.d/99-forward.conf
# Forward all logs to central logging server
*.* @@LOGSERVER_IP:514
EOF

# Reload rsyslog
sudo systemctl restart rsyslog

# Verify rsyslog is running
sudo systemctl status rsyslog
```

Test the forwarding by generating a test log:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Generate a test syslog message
logger "HOMELAB_TEST: Logging configuration test from $(hostname)"

# Check that rsyslog accepted the message
sudo journalctl -u rsyslog -n 5 --no-pager
```

## Loki + Promtail + Grafana Stack

### Loki

Loki is a log aggregation system designed for use with Prometheus and Grafana. Unlike traditional log storage (which indexes all text), Loki indexes only labels. Logs are queried with LogQL, Loki's query language.

### Promtail

Promtail is Loki's log collection agent. It scrapes logs from files or systemd journals and forwards them to Loki.

### Setup Strategy for Homelab

For small homelabs, deploy Loki + Grafana as Docker containers on a central server, and run Promtail agents on each remote host.

## Docker Compose Deployment

Create a directory for the logging stack:

```bash
#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/logging-stack/{loki,promtail,grafana}
cd ~/logging-stack
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yaml:/etc/loki/local-config.yaml
      - loki-storage:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - logging

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail/promtail-config.yaml:/etc/promtail/config.yml
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - logging
    depends_on:
      - loki

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=SecureAdminPassword123
    volumes:
      - grafana-storage:/var/lib/grafana
    networks:
      - logging
    depends_on:
      - loki

volumes:
  loki-storage:
  grafana-storage:

networks:
  logging:
    driver: bridge
```

Create `loki/loki-config.yaml`:

```yaml
auth_enabled: false

ingester:
  chunk_idle_period: 3m
  chunk_retain_period: 1m
  max_chunk_age: 1h
  chunk_encoding: snappy

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

server:
  http_listen_port: 3100
  log_level: info

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
  filesystem:
    directory: /loki/chunks
```

Create `promtail/promtail-config.yaml` (for the Loki host):

```yaml
clients:
  - url: http://loki:3100/loki/api/v1/push

positions:
  filename: /tmp/positions.yaml

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          host: primary-server
          __path__: /var/log/*log

  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
```

Deploy the stack:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/logging-stack
docker-compose up -d

# Wait for services to start
sleep 10

# Verify all services are running
docker-compose ps
```

Access Grafana at `http://localhost:3000` (default admin/SecureAdminPassword123).

Add Loki as a datasource in Grafana: Settings → Data Sources → Add Loki → URL: `http://loki:3100`.

## Log Retention Policies

Configure Loki to retain logs for a specific period:

```yaml
# In loki-config.yaml, update limits_config:
limits_config:
  retention_period: 720h  # 30 days
  retention_enabled: true
```

For rsyslog on individual hosts, rotate logs with logrotate:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Example /etc/logrotate.d/syslog config
cat << 'EOF' | sudo tee /etc/logrotate.d/syslog
/var/log/syslog
{
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /lib/systemd/systemd-syslog-startup || true
    endscript
}
EOF
```

## Filtering and Parsing Logs

Use Promtail's pipeline stages to parse and filter logs. Example: extract error level and message from a custom log format:

```yaml
scrape_configs:
  - job_name: custom_app
    static_configs:
      - targets: [localhost]
        labels:
          app: myapp
          __path__: /var/log/myapp/*.log
    pipeline_stages:
      - regex:
          expression: '(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\s+(?P<level>\w+)\s+(?P<message>.*)'
      - labels:
          level: ''
          app: ''
```

Query in Grafana using LogQL:

```
{app="myapp"} | json | level="error"
```

## Viewing Logs in Grafana

In Grafana, go to **Explore** and select Loki as the datasource.

Basic queries:
- View all logs from a service: `{job="myservice"}`
- Filter by label: `{job="myservice", level="error"}`
- Search text: `{job="myservice"} |= "timeout"`
- Exclude text: `{job="myservice"} != "health check"`
- Count logs: `count_over_time({job="myservice"}[5m])`

Create a dashboard to display:
- Error rates over time
- Top errors
- Logs from specific hosts

## journalctl Tips

journalctl is systemd's log viewer. Use it alongside centralized logging for host-level debugging:

```bash
#!/usr/bin/env bash
set -euo pipefail

# View logs from the last hour
journalctl --since "1 hour ago"

# View logs from a specific service
journalctl -u docker.service

# Follow logs in real-time
journalctl -f

# View logs with full timestamps
journalctl -o short-iso

# Export logs to a file
journalctl --no-pager > /tmp/system-logs.txt

# View logs from a specific priority level (0=emergency, 7=debug)
journalctl -p err  # Only errors and above

# View kernel logs
journalctl -k

# Vacuum old logs (keep only last 7 days)
sudo journalctl --vacuum-time=7d
```

## Troubleshooting

**Promtail not connecting to Loki:**
- Verify Loki container is running: `docker-compose ps`
- Check Promtail logs: `docker-compose logs promtail`
- Ensure firewall allows traffic on port 3100: `sudo ufw allow 3100`

**Logs not appearing in Grafana:**
- Verify Promtail is running on client hosts
- Check if the `__path__` in scrape config points to existing log files
- Ensure Loki datasource is correctly added in Grafana (test with Loki health endpoint)

**High disk usage:**
- Reduce `retention_period` in Loki config
- Lower log verbosity on clients
- Compress old logs with logrotate

**Slow log queries:**
- Use label filters instead of text search (labels are indexed)
- Narrow time range
- Increase Loki memory allocation

## Best Practices

1. **Use labels consistently**: Ensure all Promtail configs use the same labels across hosts.
2. **Avoid high-cardinality labels**: Don't use user IDs or request IDs as labels (use structured log fields instead).
3. **Centralize secrets**: Store rsyslog server IPs and credentials in environment variables or config management tools (like Ansible).
4. **Monitor the monitor**: Set up alerts on Loki itself (low disk space, high error rates).
5. **Regular retention review**: Monthly check if your retention policy matches your needs.
6. **Backup critical logs**: Export important logs periodically for compliance/archival.
7. **Test recovery**: Verify you can search and retrieve logs under normal and high-volume conditions.

## Additional Resources

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Promtail Configuration Guide](https://grafana.com/docs/loki/latest/clients/promtail/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [rsyslog Official Docs](https://www.rsyslog.com/)
- [journalctl Manual](https://man7.org/linux/man-pages/man1/journalctl.1.html)

---

✅ Centralized logging set up with Loki, Promtail, and Grafana. All servers forwarding logs to a central aggregation point.
