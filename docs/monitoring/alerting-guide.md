# 🚨 Alert Configuration Guide #monitoring #alerting #prometheus #grafana #notifications

Alerting transforms your monitoring data into actionable notifications. When a disk fills up or a service crashes, you want to know immediately—not when you check the dashboard in an hour. This guide covers setting up Prometheus alerting rules, Grafana alert channels (email, Discord, Telegram, Slack), Alertmanager for alert routing, and common homelab alerts. We'll also discuss preventing alert fatigue.

## Table of Contents

- [Alerting Concepts](#alerting-concepts)
- [Prometheus Alerting Rules](#prometheus-alerting-rules)
- [Alertmanager Setup](#alertmanager-setup)
- [Grafana Alert Channels](#grafana-alert-channels)
- [Common Homelab Alerts](#common-homelab-alerts)
- [Alert Fatigue Prevention](#alert-fatigue-prevention)
- [Silencing and Grouping](#silencing-and-grouping)
- [Testing Alerts](#testing-alerts)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Alerting Concepts

**Threshold**: A metric value that triggers an alert (e.g., CPU > 85%).

**Severity**: Alert importance level—Critical (service down), Warning (degraded), Info (for informational purposes).

**Rule**: A condition that evaluates periodically. If true, fires an alert.

**Annotation**: Human-readable description of the alert.

**Label**: Metadata (service name, host, environment) used for routing and grouping.

**Alertmanager**: Routes alerts to notifications channels, deduplicates, silences, and groups them.

## Prometheus Alerting Rules

Create a file `/etc/prometheus/rules/homelab-alerts.yml`:

```yaml
groups:
  - name: homelab
    interval: 30s
    rules:
      # Disk space alerts
      - alert: DiskSpaceRunningOut
        expr: |
          (node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs"} /
           node_filesystem_size_bytes{fstype!~"tmpfs|fuse.lxcfs"}) < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space running out on {{ $labels.instance }}"
          description: "{{ $labels.device }} has only {{ humanize $value }}% space remaining"

      # CPU alert
      - alert: HighCPUUsage
        expr: rate(node_cpu_seconds_total{mode!="idle"}[5m]) > 0.85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ humanize $value }}% (threshold: 85%)"

      # Memory alert
      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ humanize $value }}% (threshold: 90%)"

      # Service down
      - alert: ServiceDown
        expr: up{job=~"docker|node"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down on {{ $labels.instance }}"
          description: "The service has been unavailable for more than 1 minute"

      # Temperature alert (if monitoring hardware)
      - alert: HighSystemTemperature
        expr: node_hwmon_temp_celsius > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High temperature on {{ $labels.instance }}"
          description: "System temperature is {{ humanize $value }}°C"
```

Update `/etc/prometheus/prometheus.yml` to reference the rules file:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 30s

rule_files:
  - '/etc/prometheus/rules/homelab-alerts.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

Reload Prometheus (after validating config):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate the config
promtool check config /etc/prometheus/prometheus.yml

# Reload Prometheus (sends SIGHUP)
sudo systemctl reload prometheus
```

## Alertmanager Setup

Alertmanager handles alert routing, deduplication, and notification delivery.

Install Alertmanager:

```bash
#!/usr/bin/env bash
set -euo pipefail

ALERTMANAGER_VERSION="0.26.0"
cd /tmp

# Download and extract
wget "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
tar xzf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"

# Move to standard location
sudo mv "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/alertmanager" /usr/local/bin/
sudo mv "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/amtool" /usr/local/bin/

# Create config directory
sudo mkdir -p /etc/alertmanager
```

Create `/etc/alertmanager/alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'

templates:
  - '/etc/alertmanager/alert-templates.tmpl'

route:
  receiver: 'default'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 10s
      repeat_interval: 1h

    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#homelab-alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'critical-alerts'
    slack_configs:
      - channel: '#critical-alerts'
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
    email_configs:
      - to: 'homelab-admin@example.com'
        from: 'alertmanager@homelab.local'
        smarthost: 'localhost:25'
        headers:
          Subject: 'Homelab CRITICAL Alert: {{ .GroupLabels.alertname }}'

  - name: 'warning-alerts'
    slack_configs:
      - channel: '#homelab-alerts'
```

Create systemd service `/etc/systemd/system/alertmanager.service`:

```ini
[Unit]
Description=Prometheus Alertmanager
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
#!/usr/bin/env bash
set -euo pipefail

sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
sudo systemctl status alertmanager
```

Verify Alertmanager is accessible at `http://localhost:9093`.

## Grafana Alert Channels

Grafana can send alerts directly, independent of Prometheus Alertmanager.

In Grafana, go to **Alerting → Notification channels** and add channels.

### Email Channel

- **Type**: Email
- **Email address**: your-email@example.com
- **SMTP settings**: Configure in Grafana's config (`/etc/grafana/grafana.ini`)

```ini
[smtp]
enabled = true
host = smtp.gmail.com:587
user = your-email@gmail.com
# Do not hardcode password; use environment variables
password = ${GRAFANA_SMTP_PASSWORD}
skip_verify = false
from_address = grafana@homelab.local
```

### Slack Channel

- **Type**: Slack
- **Webhook URL**: Create an incoming webhook in Slack (Apps → Create New App → Incoming Webhooks)
- Test by clicking **Send Test**

### Discord Channel

- **Type**: Discord
- **Webhook URL**: In Discord, create a webhook in your channel settings
- **Message content**: Customize alert templates

### Telegram Channel

- **Type**: Telegram
- **Bot token**: Create bot via @BotFather in Telegram
- **Chat ID**: Your Telegram user or group ID
- Example setup:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Send a test message to Telegram via cURL
BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
MESSAGE="Homelab Alert System Test"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -H 'Content-Type: application/json' \
  -d "{\"chat_id\": ${CHAT_ID}, \"text\": \"${MESSAGE}\"}"
```

## Common Homelab Alerts

Essential alerts for a small homelab:

1. **Disk Space**: Alert when any partition is > 80% full
2. **CPU/Memory**: Alert when sustained high usage (avoid brief spikes)
3. **Service Down**: Alert immediately if critical services stop
4. **Network**: High packet loss or latency
5. **Temperature**: If hardware monitoring available
6. **Backup Failure**: Alert if daily backups don't complete
7. **Certificate Expiry**: Alert if SSL certs expire soon

Example Prometheus rule for certificate expiry:

```yaml
- alert: CertificateExpiring
  expr: ssl_cert_expires_in_days < 30
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Certificate expiring soon on {{ $labels.instance }}"
    description: "Certificate {{ $labels.cert_name }} expires in {{ $value }} days"
```

## Alert Fatigue Prevention

Too many alerts = ignored alerts. Prevent alert fatigue:

1. **Tune thresholds**: Set realistic thresholds. 85% CPU is a warning, 95% is critical.
2. **Use `for` clauses**: Require the condition to be true for a duration (e.g., `for: 10m`) to filter transient spikes.
3. **Group related alerts**: Route similar alerts to the same channel; avoid duplicates.
4. **Repeat interval**: Set `repeat_interval` in Alertmanager so you're reminded of ongoing issues, not spammed.
5. **Silence routine tasks**: During maintenance, silence irrelevant alerts.
6. **Progressive escalation**: Warning → team Slack. Critical → critical Slack + email.

## Silencing and Grouping

Silence alerts during maintenance:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Silence all alerts for a host during maintenance (via amtool)
amtool silence add alertname=DiskSpaceRunningOut instance="192.168.1.10:9100" \
  --duration 2h --comment "Disk cleanup in progress"

# List active silences
amtool silence

# Remove a silence
amtool silence expire <silence-id>
```

In Alertmanager config, group alerts by service and severity:

```yaml
route:
  group_by: ['alertname', 'service', 'severity']
  group_wait: 30s       # Wait 30s to batch alerts
  group_interval: 5m    # Resend grouped alerts every 5m
  repeat_interval: 4h   # Repeat unresolved alerts every 4h
```

## Testing Alerts

Test Prometheus alert rules:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Manually trigger a test alert by setting a metric above threshold
# (useful if you have a test VM or service)

# Test DNS alert - if a service is down
# Kill the service: sudo systemctl stop myservice
# Wait for alert to fire (check Prometheus Alerts tab)
# Restart: sudo systemctl start myservice
```

Test Alertmanager webhook delivery:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Send a test alert to Alertmanager
curl -XPOST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning"
    },
    "annotations": {
      "summary": "This is a test alert",
      "description": "Testing alert routing"
    },
    "generatorURL": "http://prometheus:9090/graph"
  }]'
```

## Troubleshooting

**Alerts not firing:**
- Check Prometheus rule syntax: `promtool check rules /etc/prometheus/rules/*.yml`
- Verify metrics exist: query them in Prometheus UI
- Check `evaluation_interval` is short enough (default 30s)
- Look at Prometheus logs: `journalctl -u prometheus -f`

**Alerts firing too frequently:**
- Increase the `for:` duration (e.g., `for: 10m`)
- Raise the threshold slightly
- Check for metric noise (disk I/O spikes)

**Notifications not received:**
- Verify Alertmanager is running: `systemctl status alertmanager`
- Check Alertmanager logs: `journalctl -u alertmanager -f`
- Test webhook URLs manually (curl them)
- Verify receiver email/Slack/Discord settings

**Duplicate alerts:**
- Check Prometheus rule syntax (no unintended rule duplication)
- Verify Alertmanager `group_by` is set correctly

## Best Practices

1. **Start simple**: Begin with critical alerts (service down, disk full), add more as you refine thresholds.
2. **Document thresholds**: In the rule annotations, explain why you chose each threshold.
3. **Test before going live**: Trigger test alerts to verify notifications reach you.
4. **Review regularly**: Monthly, check if alerts are actionable and adjust thresholds.
5. **Escalation policy**: Define who gets what alerts and when (e.g., Slack during business hours, SMS after hours).
6. **Track MTTR**: Measure alert-to-resolution time and improve processes.
7. **Secrets management**: Never hardcode Slack tokens, email passwords in configs. Use environment variables or secret management tools.

## Additional Resources

- [Prometheus Alerting Documentation](https://prometheus.io/docs/alerting/latest/overview/)
- [Alertmanager Configuration Guide](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Alerting Docs](https://grafana.com/docs/grafana/latest/alerting/)
- [Common Prometheus Alerts](https://awesome-prometheus-alerts.grep.to/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)

---

✅ Alerting configured with Prometheus rules, Alertmanager routing, and notifications to Slack, Discord, and email.
