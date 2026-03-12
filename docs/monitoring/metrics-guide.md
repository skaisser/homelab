# 📈 Performance Metrics Guide #monitoring #metrics #prometheus #grafana #node-exporter

Metrics are time-series data about your infrastructure: CPU usage, memory, disk I/O, network throughput. Unlike logs, metrics are aggregated and queryable at scale. This guide covers setting up Prometheus for metrics collection, Node Exporter for host-level metrics, Grafana for visualization, and key dashboards for a homelab.

## Table of Contents

- [What Metrics to Collect](#what-metrics-to-collect)
- [Prometheus Overview](#prometheus-overview)
- [Node Exporter Setup](#node-exporter-setup)
- [Docker Compose Deployment](#docker-compose-deployment)
- [PromQL Basics](#promql-basics)
- [Grafana Dashboard Creation](#grafana-dashboard-creation)
- [Key Dashboards](#key-dashboards)
- [Custom Metrics](#custom-metrics)
- [Data Retention and Storage](#data-retention-and-storage)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## What Metrics to Collect

In a homelab, focus on:
- **Host-level**: CPU, memory, disk, network (from Node Exporter)
- **Container-level**: Docker stats, if running containers
- **Application-level**: Request latency, error rates, custom business metrics
- **Infrastructure**: Temperature, power usage (if hardware supports it)

Start with host-level metrics, then add application-specific metrics as needed.

## Prometheus Overview

Prometheus is a time-series database and monitoring system. It:
- **Scrapes** metrics from exporters and services
- **Stores** them efficiently with compression
- **Queries** them with PromQL language
- **Evaluates** alerting rules
- **Exposes** metrics for visualization in Grafana

Key concepts:
- **Exporter**: A service that exposes metrics (e.g., Node Exporter for host metrics)
- **Scrape target**: A host:port that Prometheus polls for metrics
- **Job**: A collection of scrape targets (e.g., all node exporters are job=node)
- **Label**: Metadata on a metric (e.g., instance, job, environment)
- **Time series**: A metric with specific label values over time

## Node Exporter Setup

Node Exporter exposes system metrics: CPU, memory, disk, network, processes, etc.

Install Node Exporter on each host:

```bash
#!/usr/bin/env bash
set -euo pipefail

NODE_EXPORTER_VERSION="1.7.0"
cd /tmp

# Download and extract
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

# Move to standard location
sudo mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/node-exporter.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create prometheus user if not exists
sudo useradd -r prometheus 2>/dev/null || true

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable node-exporter
sudo systemctl start node-exporter

# Verify it's running (default port 9100)
curl -s http://localhost:9100/metrics | head -20
```

Verify metrics are exposed:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Should show metrics like node_cpu_seconds_total, node_memory_MemTotal_bytes, etc.
curl -s http://localhost:9100/metrics | grep -E "^node_" | head -10
```

## Docker Compose Deployment

For a centralized Prometheus + Grafana setup, use Docker Compose.

Create `~/monitoring/docker-compose.yml`:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./rules.yml:/etc/prometheus/rules.yml
      - prometheus-storage:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=SecurePassword123
    volumes:
      - grafana-storage:/var/lib/grafana
    networks:
      - monitoring
    depends_on:
      - prometheus

volumes:
  prometheus-storage:
  grafana-storage:

networks:
  monitoring:
    driver: bridge
```

Create `~/monitoring/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
      # Add more node exporters here:
      # - targets: ['192.168.1.10:9100', '192.168.1.11:9100']

  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:8080']  # If using cAdvisor
```

Deploy:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/monitoring
docker-compose up -d
sleep 10
docker-compose ps
```

Access Prometheus at `http://localhost:9090` and Grafana at `http://localhost:3000`.

## PromQL Basics

PromQL is Prometheus's query language. Common queries:

```promql
# View a metric
node_cpu_seconds_total

# Calculate CPU usage percentage
rate(node_cpu_seconds_total{mode!="idle"}[5m]) * 100

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage percentage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# Requests per second
rate(http_requests_total[5m])

# P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Count instances in a job
count(up{job="node"})

# Alert if CPU > 80% for 5m
avg(rate(node_cpu_seconds_total{mode!="user"}[5m])) > 0.8
```

In Prometheus UI, go to **Graph** and paste PromQL queries to test.

## Grafana Dashboard Creation

Add Prometheus as a datasource in Grafana:
1. Go to **Configuration → Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Set URL to `http://prometheus:9090`
5. Click **Save & Test**

Create a dashboard:
1. Go to **Create → Dashboard**
2. Click **Add Panel**
3. In the **Metrics** dropdown, select Prometheus
4. Enter a PromQL query
5. Customize title, legend, visualization type
6. Click **Save**

Example panel queries:

**CPU Usage**:
```promql
rate(node_cpu_seconds_total{mode!="idle"}[5m]) * 100
```
- Visualization: Graph
- Legend: `{{ instance }}`

**Memory Usage**:
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```
- Visualization: Gauge (show percentage)

**Disk Usage**:
```promql
(1 - (node_filesystem_avail_bytes{fstype!~"tmpfs"} / node_filesystem_size_bytes{fstype!~"tmpfs"})) * 100
```
- Visualization: Table

## Key Dashboards

### Node Exporter Full

Community dashboards are available. Import the official Node Exporter dashboard:
1. Go to **+ → Import**
2. Enter dashboard ID `1860` (Node Exporter Full)
3. Select Prometheus as datasource
4. Click **Import**

This shows CPU, memory, disk, network, system info.

### Docker

If running Docker:
1. Install cAdvisor (Container Advisor): `docker run -d --name cadvisor --volume=/:/rootfs:ro --volume=/var/run:/var/run:ro --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro -p 8080:8080 gcr.io/cadvisor/cadvisor:latest`
2. Add cAdvisor scrape target in Prometheus config
3. Import Docker dashboard (ID `179`)

### Network

Monitor network metrics:
```promql
rate(node_network_receive_bytes_total[5m])  # Network RX
rate(node_network_transmit_bytes_total[5m]) # Network TX
```

Create a graph panel with both queries.

## Custom Metrics

Expose custom metrics from your applications. Example in Python with Prometheus client:

```python
#!/usr/bin/env python3
from prometheus_client import Counter, Gauge, start_http_server
import time

# Define custom metrics
request_count = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
processing_time = Gauge('app_processing_seconds', 'Processing time')

def handle_request(method, endpoint):
    request_count.labels(method=method, endpoint=endpoint).inc()
    processing_time.set(0.42)

# Start metrics server on port 8000
start_http_server(8000)

# Simulate requests
while True:
    handle_request('GET', '/api/status')
    time.sleep(5)
```

Add to Prometheus config:

```yaml
scrape_configs:
  - job_name: 'custom-app'
    static_configs:
      - targets: ['localhost:8000']
```

Query custom metrics:

```promql
rate(app_requests_total[5m])
app_processing_seconds
```

## Data Retention and Storage

Prometheus stores time-series data locally. Control retention:

**By time**:
```bash
prometheus --storage.tsdb.retention.time=30d
```

**By size**:
```bash
prometheus --storage.tsdb.retention.size=10GB
```

In Docker Compose, add to Prometheus command:
```yaml
command:
  - '--storage.tsdb.retention.time=30d'
  - '--storage.tsdb.retention.size=10GB'
```

Monitor storage usage:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check Prometheus storage size
du -sh /var/lib/prometheus/  # Or wherever Docker volume is mounted
```

For long-term retention, use remote storage (Thanos, InfluxDB, or cloud providers), but overkill for homelab.

## Troubleshooting

**Metrics not appearing in Prometheus:**
- Verify scrape target is reachable: `curl http://target:port/metrics`
- Check Prometheus scrape configs: **Status → Targets**
- Look for errors in Prometheus logs: `docker-compose logs prometheus`

**Grafana can't connect to Prometheus:**
- Verify Prometheus container is running: `docker-compose ps`
- Check datasource URL (should be `http://prometheus:9090` in Docker)
- Click **Test** on the datasource config

**High Prometheus memory usage:**
- Reduce scrape interval (`scrape_interval: 30s` instead of 15s)
- Reduce retention time (`--storage.tsdb.retention.time=7d`)
- Drop unnecessary metrics: use `metric_relabel_configs`

**PromQL query returning no data:**
- Verify metric name (case-sensitive): check Prometheus **Graph → Metrics**
- Check label filters: `node_cpu_seconds_total{instance="localhost:9100"}`
- Ensure time range has data (default is 1 hour)

## Best Practices

1. **Use consistent labels**: Ensure all targets use the same label structure (instance, job).
2. **Avoid high cardinality**: Don't label by request ID or user ID (leads to metric explosion).
3. **Scrape interval tuning**: Balance between granularity (15s) and storage (30s or 1m for non-critical).
4. **Regular dashboards review**: Update dashboards as infrastructure changes.
5. **Document thresholds**: In dashboard descriptions, explain why thresholds exist.
6. **Backup Grafana dashboards**: Export dashboards as JSON and version them.
7. **Test PromQL queries**: Use Prometheus UI before adding to dashboards.

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/prometheus/latest/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Node Exporter Metrics Reference](https://github.com/prometheus/node_exporter)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Grafana Prometheus Documentation](https://grafana.com/docs/grafana/latest/datasources/prometheus/)

---

✅ Metrics collection set up with Prometheus, Node Exporter, and Grafana dashboards for CPU, memory, disk, and network monitoring.
