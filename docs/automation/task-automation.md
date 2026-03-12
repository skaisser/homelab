# ⏰ Cron and Systemd Task Automation #automation #cron #systemd #scheduling

Learn to schedule and automate tasks in your homelab using cron jobs and systemd timers. Master both traditional and modern Linux scheduling approaches with practical examples.

## Table of Contents
- [Cron Syntax and Concepts](#cron-syntax-and-concepts)
- [Crontab Management](#crontab-management)
- [Cron Examples](#cron-examples)
- [Systemd Timer Units](#systemd-timer-units)
- [Systemd Timer Examples](#systemd-timer-examples)
- [Cron vs Systemd Timers](#cron-vs-systemd-timers)
- [Common Homelab Tasks](#common-homelab-tasks)
- [Logging and Monitoring](#logging-and-monitoring)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Cron Syntax and Concepts

**Cron schedule format:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (0 is Sunday, 6 is Saturday)
│ │ │ │ │
│ │ │ │ │
* * * * * <command to execute>
```

**Special time specifications:**
```bash
@reboot         # Run at startup
@yearly         # Every January 1st at midnight
@annually       # Same as @yearly
@monthly        # Every 1st of month at midnight
@weekly         # Every Sunday at midnight
@daily          # Every day at midnight
@midnight       # Same as @daily
@hourly         # Every hour at minute 0
```

**Common syntax patterns:**
```bash
0 0 * * *       # Every day at midnight
0 * * * *       # Every hour
*/15 * * * *    # Every 15 minutes
0 2 * * 0       # Every Sunday at 2 AM
0 0 1 * *       # First day of every month
0 0 1 1 *       # January 1st at midnight
30 4 * * 1-5    # Weekdays at 4:30 AM
*/5 9-17 * * *  # Every 5 minutes during business hours (9am-5pm)
0 */4 * * *     # Every 4 hours
0 0 * * MON     # Every Monday at midnight
```

## Crontab Management

**View and edit crontab:**
```bash
# List current user's crontab
crontab -l

# List another user's crontab (as root)
sudo crontab -u username -l

# Edit crontab (opens in default editor)
crontab -e

# Edit another user's crontab
sudo crontab -u username -e

# Install crontab from file
crontab /path/to/crontab.txt

# Remove current user's crontab
crontab -r

# Remove another user's crontab
sudo crontab -u username -r

# Set editor for crontab
EDITOR=nano crontab -e
```

**System-wide crontab:**
```bash
# Edit system crontab
sudo nano /etc/crontab

# Format includes username for system crontab
0 2 * * * root /opt/app/daily-backup.sh

# Drop-in directory for system cron jobs
sudo nano /etc/cron.d/myapp-tasks

# Contents of /etc/cron.d/myapp-tasks
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 1 * * * root /opt/myapp/backup.sh >> /var/log/myapp-backup.log 2>&1
```

**Predefined cron directories:**
```bash
/etc/cron.hourly/    # Scripts to run hourly
/etc/cron.daily/     # Scripts to run daily
/etc/cron.weekly/    # Scripts to run weekly
/etc/cron.monthly/   # Scripts to run monthly

# Add script to daily execution
sudo cp /opt/app/daily-task.sh /etc/cron.daily/
sudo chmod 755 /etc/cron.daily/daily-task.sh
```

## Cron Examples

**Basic backup cron job:**
```bash
# Daily backup at 2 AM
0 2 * * * /opt/app/backup.sh

# Backup output to log
0 2 * * * /opt/app/backup.sh >> /var/log/backup.log 2>&1

# Run with explicit shell and user
0 2 * * * root /bin/bash /opt/app/backup.sh

# Run with environment variables
0 2 * * * /usr/bin/env PATH=/usr/bin:/bin /opt/app/backup.sh
```

**Multiple frequency examples:**
```bash
# Every 30 minutes
*/30 * * * * /opt/app/health-check.sh

# Every 6 hours
0 */6 * * * /opt/app/sync-data.sh

# Twice daily (8 AM and 8 PM)
0 8,20 * * * /opt/app/report.sh

# Business hours every 2 hours
0 9-17/2 * * 1-5 /opt/app/monitor.sh

# Every hour on Monday, Wednesday, Friday
0 * * * 1,3,5 /opt/app/special-task.sh

# Except on weekends
0 2 * * 1-5 /opt/app/weekday-backup.sh
```

**Piping and output handling:**
```bash
# Log to file with timestamp
0 2 * * * /opt/app/backup.sh >> /var/log/backup.log 2>&1

# Only log on error
0 2 * * * /opt/app/backup.sh > /dev/null 2>&1 || echo "Backup failed"

# Email on error
0 2 * * * /opt/app/backup.sh || echo "Backup failed" | mail -s "Error" admin@example.com

# Append to log with date
0 2 * * * date >> /var/log/tasks.log && /opt/app/backup.sh >> /var/log/tasks.log 2>&1
```

## Systemd Timer Units

**Systemd timer structure:**
```bash
# Timer file: /etc/systemd/system/myapp-backup.timer
[Unit]
Description=MyApp Backup Timer
Requires=myapp-backup.service

[Timer]
OnBootSec=10min              # 10 minutes after boot
OnUnitActiveSec=1d           # 1 day after last run
Persistent=true              # Catch up if system was off

[Install]
WantedBy=timers.target

# Service file: /etc/systemd/system/myapp-backup.service
[Unit]
Description=MyApp Backup Service
After=network.target

[Service]
Type=oneshot
User=backup
ExecStart=/opt/app/backup.sh
StandardOutput=journal
StandardError=journal
```

**Create and enable systemd timer:**
```bash
# Create the service file
sudo tee /etc/systemd/system/backup.service > /dev/null <<'EOF'
[Unit]
Description=Daily Backup
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/app/backup.sh
StandardOutput=journal
StandardError=journal
EOF

# Create the timer file
sudo tee /etc/systemd/system/backup.timer > /dev/null <<'EOF'
[Unit]
Description=Daily Backup Timer
Requires=backup.service

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 02:00:00

[Install]
WantedBy=timers.target
EOF

# Reload systemd, enable, and start
sudo systemctl daemon-reload
sudo systemctl enable backup.timer
sudo systemctl start backup.timer

# Check status
sudo systemctl status backup.timer
```

**Systemd timer time specifications:**
```bash
# OnCalendar format: DayOfWeek Year-Month-Day Hour:Minute:Second

OnCalendar=daily           # Every day at midnight
OnCalendar=*-*-* 02:00:00  # Every day at 2 AM
OnCalendar=Mon *-*-* 09:00:00  # Every Monday at 9 AM
OnCalendar=*-01-01 00:00:00    # Every January 1st
OnCalendar=*-*-01 00:00:00     # First day of every month
OnCalendar=*-*-* 09:00:00      # Every day at 9 AM
OnCalendar=*-*-* 09,14,19:00:00  # At 9 AM, 2 PM, and 7 PM
OnCalendar=*-*-* *:0/15:00     # Every 15 minutes

# OnBootSec and OnUnitActiveSec
OnBootSec=5min            # 5 minutes after boot
OnUnitActiveSec=1h        # 1 hour after last execution
OnUnitActiveSec=2d        # 2 days after last execution
```

## Systemd Timer Examples

**Hourly health check:**
```bash
# /etc/systemd/system/health-check.timer
[Unit]
Description=Hourly Health Check
Requires=health-check.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target

# /etc/systemd/system/health-check.service
[Unit]
Description=Health Check Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/health-check.sh
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
```

**Weekly cleanup with randomized start:**
```bash
# /etc/systemd/system/cleanup.timer
[Unit]
Description=Weekly Cleanup Timer
Requires=cleanup.service

[Timer]
OnCalendar=Sun *-*-* 03:00:00
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target

# /etc/systemd/system/cleanup.service
[Unit]
Description=Cleanup Service
After=network.target

[Service]
Type=oneshot
User=cleanup
ExecStart=/opt/app/cleanup.sh
StandardOutput=journal
StandardError=journal
```

**Multiple scheduled times:**
```bash
# /etc/systemd/system/backup.timer
[Unit]
Description=Backup Timer (Multiple Times)
Requires=backup.service

[Timer]
OnCalendar=*-*-* 02:00:00     # Every day at 2 AM
OnCalendar=*-*-* 14:00:00     # Every day at 2 PM
Persistent=true

[Install]
WantedBy=timers.target
```

## Cron vs Systemd Timers

| Feature | Cron | Systemd Timers |
|---------|------|-----------------|
| **Syntax** | Concise field format | INI-style config |
| **Reliability** | Good | Excellent |
| **Logging** | Often to files | Journal integration |
| **Dependencies** | Limited | Full service management |
| **Monitoring** | Manual checking | `systemctl status` |
| **Catch-up** | No | Optional (Persistent=true) |
| **Accuracy** | Minute-level | Second-level |
| **Resource use** | Minimal | Minimal |
| **Learning curve** | Easy | Moderate |

**Choose cron when:**
- Running simple, lightweight tasks
- Need maximum compatibility
- Quick one-off scheduling

**Choose systemd when:**
- Building complex automation
- Need reliable logging and monitoring
- Want dependency management
- Running modern Linux systems

## Common Homelab Tasks

**Docker container updates:**
```bash
# Cron version
0 2 * * * docker pull myregistry/myapp:latest && docker-compose -f /opt/app/docker-compose.yml up -d

# Systemd version
[Service]
ExecStart=/usr/bin/docker pull myregistry/myapp:latest
ExecStart=/usr/bin/docker-compose -f /opt/app/docker-compose.yml up -d
```

**Certificate renewal:**
```bash
# Using cron for Let's Encrypt
0 3 * * 0 certbot renew --quiet --post-hook "systemctl reload nginx"

# Using systemd
[Service]
ExecStart=/usr/bin/certbot renew --quiet
ExecStartPost=/bin/systemctl reload nginx
```

**Database backups:**
```bash
# Cron
0 1 * * * /usr/bin/mysqldump -u backup -p'password' --all-databases | gzip > /backups/db-$(date +\%Y\%m\%d).sql.gz

# Systemd
[Service]
ExecStart=/usr/bin/bash -c '/usr/bin/mysqldump -u backup -p"password" --all-databases | gzip > /backups/db-$(date +%%Y%%m%%d).sql.gz'
```

**Log rotation and cleanup:**
```bash
# System logs are typically handled by logrotate in /etc/logrotate.d/

# Custom cleanup cron job
0 0 * * * find /var/log -name "*.log" -mtime +30 -delete
0 0 * * * find /tmp -type f -atime +7 -delete
```

**Docker cleanup:**
```bash
# Remove unused images and containers
0 3 * * 0 docker image prune -a -f && docker container prune -f
```

## Logging and Monitoring

**View cron execution logs:**
```bash
# Check system logs for cron execution
sudo journalctl -u cron --since today

# Check mail log (cron sends output to local user email)
sudo tail -f /var/log/mail.log

# View syslog
sudo grep CRON /var/log/syslog | tail -20
```

**Monitor systemd timers:**
```bash
# List all active timers
sudo systemctl list-timers

# List all timers including inactive
sudo systemctl list-timers --all

# Check specific timer status
sudo systemctl status backup.timer

# View timer details
sudo systemctl show -p NextElapses backup.timer

# View unit activity log
sudo journalctl -u backup.service -n 50

# Real-time monitoring
sudo journalctl -u backup.service -f
```

**Add logging to cron jobs:**
```bash
# Wrapper script with logging
#!/bin/bash
LOG_FILE="/var/log/myapp/backup.log"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting backup" >> "$LOG_FILE"

if /opt/app/backup.sh >> "$LOG_FILE" 2>&1; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup completed successfully" >> "$LOG_FILE"
else
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup failed" >> "$LOG_FILE"
  exit 1
fi
```

**Systemd service logging:**
```bash
# Logs automatically go to journal
# View all output
journalctl -u backup.service

# View with timestamps
journalctl -u backup.service --no-pager -o short-iso

# Follow logs in real-time
journalctl -u backup.service -f

# Last 100 lines
journalctl -u backup.service -n 100
```

## Troubleshooting

**Cron job not running:**
```bash
# Check if cron service is running
sudo systemctl status cron

# Restart cron service
sudo systemctl restart cron

# Check crontab syntax
crontab -l | grep -v "^#"

# Test cron job manually
/bin/bash /opt/app/backup.sh

# Check cron logs
sudo journalctl -u cron -f

# Verify user's cron permissions
ls -la /etc/cron.allow /etc/cron.deny
```

**Systemd timer not executing:**
```bash
# Check timer status
sudo systemctl status myapp.timer

# Check if timer is enabled
sudo systemctl is-enabled myapp.timer

# Check service status
sudo systemctl status myapp.service

# View timer calendar
sudo systemctl list-timers myapp.timer --all

# Manually run service for testing
sudo systemctl start myapp.service

# View detailed journal output
journalctl -u myapp.service -n 100
```

**Common cron issues:**
```bash
# Issue: Environment variables not available
# Solution: Set variables in crontab
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOME=/root
0 2 * * * /opt/app/backup.sh

# Issue: Command not found
# Solution: Use absolute paths
0 2 * * * /usr/bin/bash /opt/app/backup.sh

# Issue: Output redirects not working
# Solution: Use full path for redirection
0 2 * * * /opt/app/backup.sh > /var/log/backup.log 2>&1

# Issue: Directory doesn't exist
# Solution: Create directory in script or crontab
0 2 * * * mkdir -p /backups && /opt/app/backup.sh > /backups/backup.log 2>&1
```

## Best Practices

1. **Use absolute paths** - Cron/systemd don't have your shell environment
2. **Log everything** - Know when tasks run and if they succeeded
3. **Test manually first** - Run scripts before scheduling
4. **Use root sparingly** - Run tasks as least-privilege user
5. **Handle errors** - Script should exit with proper codes
6. **Monitor execution** - Regularly check logs
7. **Document schedules** - Comment why tasks run when they do
8. **Use systemd for new setups** - More features and better monitoring
9. **Set timeouts** - Prevent hung tasks from blocking others
10. **Separate concerns** - One task per unit/cron entry

## Additional Resources

- [Cron Format and Examples](https://crontab.guru/)
- [Systemd Timer Documentation](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Systemd OnCalendar Format](https://www.freedesktop.org/software/systemd/man/systemd.time.html)
- [Linux Cron Beginners Guide](https://www.linuxfoundation.org/blog/blog/classic-sysadmin-how-to-use-cron-and-crontab)

---

✅ Complete task automation guide covering cron scheduling, systemd timers, common homelab tasks, logging strategies, and troubleshooting for reliable automation.
