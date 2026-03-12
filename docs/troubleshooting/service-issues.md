# 🚀 Service & Application Troubleshooting #troubleshooting #services #docker #systemd

Debugging guide for services that won't start, Docker containers, reverse proxy issues, SSL certificates, and database connectivity problems.

## Table of Contents
1. [Service Won't Start](#service-wont-start)
2. [Docker Container Issues](#docker-container-issues)
3. [Port Conflicts](#port-conflicts)
4. [Dependency Problems](#dependency-problems)
5. [Reverse Proxy Issues](#reverse-proxy-issues)
6. [SSL/TLS Certificate Issues](#ssltls-certificate-issues)
7. [Database Connectivity](#database-connectivity)
8. [Application Debugging](#application-debugging)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Service Won't Start

### Systemctl Diagnostics
```bash
# Check detailed status
sudo systemctl status servicename

# Show journal entries for service
sudo journalctl -u servicename -n 50 -e

# Check if service is enabled
sudo systemctl is-enabled servicename

# List dependencies
sudo systemctl show servicename -p Requires

# Check service conflicts
sudo systemctl show servicename -p Conflicts

# Verify unit file syntax
sudo systemd-analyze verify /etc/systemd/system/servicename.service

# Debug service startup
systemd-run --user -t bash -c 'exec 2>&1; /usr/bin/servicename'
```

### Permission and File Issues
```bash
# Check if all required files exist
ls -la /etc/servicename/
ls -la /var/lib/servicename/
ls -la /var/log/servicename/

# Verify service has correct permissions
stat /etc/systemd/system/servicename.service

# Check if service user exists
id servicename

# Verify service can read its config
sudo -u servicename cat /etc/servicename/config.conf

# Check directory ownership
sudo ls -la /var/lib/servicename/

# Fix permissions if needed
sudo chown -R servicename:servicename /var/lib/servicename/
sudo chmod -R 755 /var/lib/servicename/
```

### Common Service Issues
```bash
# Service user doesn't exist
sudo useradd -r -s /bin/false servicename

# Service can't find dependencies
sudo apt-get install libdependency

# Invalid configuration file
sudo servicename --validate-config

# Port already in use (see Port Conflicts section)
sudo lsof -i :8080

# Check service environment variables
grep -i environ /etc/systemd/system/servicename.service
```

## Docker Container Issues

### Container Won't Start
```bash
# Check container status
docker ps -a

# View detailed container info
docker inspect containername

# Check creation errors
docker logs containername --tail 100

# Real-time logs during startup
docker logs -f containername

# Check container events
docker events --filter 'container=containername'

# Attempt to start with debugging
docker run --rm -it imagename /bin/bash

# Check image integrity
docker inspect imagename
```

### Common Docker Issues
```bash
# Image not found locally
docker images

# Pull missing image
docker pull imagename:tag

# Check image layers
docker history imagename

# Container out of disk space
docker system df

# Clean up unused images
docker image prune

# Remove dangling layers
docker image prune -a

# Check container resource limits
docker inspect containername | grep -A 10 HostConfig
```

### Container Execution Debugging
```bash
# Execute command in running container
docker exec containername /bin/bash

# Execute with interactive terminal
docker exec -it containername /bin/bash

# Check running processes in container
docker exec containername ps aux

# Monitor container resource usage
docker stats containername

# View container network settings
docker inspect --format='{{json .NetworkSettings}}' containername

# Check environment variables
docker inspect --format='{{json .Config.Env}}' containername
```

### Docker Network Issues
```bash
# List networks
docker network ls

# Inspect container's network
docker network inspect containername

# Check DNS resolution inside container
docker exec containername nslookup servicename

# Test connectivity between containers
docker exec container1 ping container2

# Check exposed ports
docker port containername

# View iptables rules (Docker modifies these)
sudo iptables -t nat -L -n -v | grep docker
```

## Port Conflicts

### Find Service Using Port
```bash
# Find what's using a port
sudo lsof -i :8080

# Using ss command
sudo ss -tulpn | grep :8080

# Using netstat
sudo netstat -tulpn | grep :8080

# Find all listening ports
sudo lsof -i -P -n | grep LISTEN

# Get process ID using port
sudo fuser 8080/tcp
```

### Resolve Port Conflicts
```bash
# Stop conflicting service
sudo systemctl stop servicename

# Kill process using port
sudo kill -9 PID

# Change service port in config
sudo nano /etc/servicename/config.conf

# Check port is free after changes
sudo ss -tulpn | grep :8080

# Reload service with new port
sudo systemctl restart servicename

# Verify service now bound to new port
sudo ss -tulpn | grep servicename
```

### Port Binding Issues
```bash
# Service bound to wrong interface (127.0.0.1 instead of 0.0.0.0)
sudo netstat -tulpn | grep servicename

# Check service config for bind address
grep -i bind /etc/servicename/config.conf

# Fix bind address in config
sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/servicename/config.conf

# Verify binding after restart
sudo systemctl restart servicename
sudo netstat -tulpn | grep servicename
```

## Dependency Problems

### Check Dependencies
```bash
# List service dependencies
sudo systemctl show servicename -p Requires

# Check what service requires
sudo systemctl show servicename -p RequiredBy

# Display dependency tree
systemctl list-dependencies servicename --tree

# Check if required service is running
sudo systemctl is-active requireddependency

# Start dependency
sudo systemctl start requireddependency

# Enable dependency on boot
sudo systemctl enable requireddependency
```

### Library Dependency Issues
```bash
# Find missing libraries
ldd /usr/bin/servicename

# Install missing library
sudo apt-get install libmissingname

# Check library path
ldconfig -p | grep libname

# Add library path if needed
echo "/usr/lib/custom" | sudo tee -a /etc/ld.so.conf.d/custom.conf
sudo ldconfig
```

### Service Dependency Order
```bash
# Wrong startup order - add After/Before
sudo nano /etc/systemd/system/servicename.service
# Add to [Unit] section:
# After=requiredservice.service
# Requires=requiredservice.service

# Reload systemd and restart
sudo systemctl daemon-reload
sudo systemctl restart servicename

# Verify ordering
systemctl list-dependencies servicename --tree
```

## Reverse Proxy Issues

### Nginx Reverse Proxy Debugging
```bash
# Check nginx syntax
sudo nginx -t

# View nginx config
sudo cat /etc/nginx/nginx.conf

# Check specific server block
sudo cat /etc/nginx/sites-available/sitename

# Enable/disable site
sudo a2ensite sitename
sudo a2dissite sitename

# Reload nginx
sudo systemctl reload nginx

# Monitor nginx logs
sudo tail -f /var/log/nginx/error.log

# Check upstream connectivity
sudo journalctl -u nginx -f
```

### Common Reverse Proxy Problems
```bash
# Test backend connectivity
curl -v http://backendserver:8080/

# Check backend is listening
sudo ss -tulpn | grep 8080

# Verify proxy config points to correct backend
grep -i upstream /etc/nginx/sites-available/sitename

# Check hostname resolution in proxy config
grep -i proxy_pass /etc/nginx/sites-available/sitename

# Docker backend connectivity
docker network inspect bridge_name
docker exec frontend ping backend_container
```

### Proxy Headers and SSL
```bash
# Check X-Real-IP is being set
sudo grep -i x-real-ip /etc/nginx/nginx.conf

# Add if missing:
# proxy_set_header X-Real-IP $remote_addr;
# proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
# proxy_set_header X-Forwarded-Proto $scheme;

# Test with curl
curl -H "X-Forwarded-For: 192.168.1.1" http://localhost/

# View what backend receives
# In backend app, log $HTTP_X_FORWARDED_FOR
```

## SSL/TLS Certificate Issues

### Certificate Validation
```bash
# Check certificate details
openssl x509 -in /etc/ssl/certs/mycert.crt -text -noout

# Check certificate chain
openssl s_client -connect myserver.com:443 -showcerts

# Verify certificate is valid
openssl verify -CAfile /etc/ssl/certs/ca.crt /etc/ssl/certs/mycert.crt

# Check expiration date
openssl x509 -in /etc/ssl/certs/mycert.crt -noout -dates

# Check certificate key matches
openssl x509 -noout -modulus -in /etc/ssl/certs/mycert.crt | openssl md5
openssl rsa -noout -modulus -in /etc/ssl/private/mycert.key | openssl md5
```

### Let's Encrypt / Certbot Issues
```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot certonly --webroot -w /var/www/html -d mysite.com

# Renew certificate
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal

# Test renewal process
sudo certbot renew --dry-run

# Check renewal cron/timer
sudo systemctl list-timers | grep certbot
sudo journalctl -u certbot.timer -f
```

### Certificate Configuration
```bash
# Add certificate to nginx
sudo nano /etc/nginx/sites-available/sitename
# Add:
# ssl_certificate /etc/letsencrypt/live/mysite.com/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/mysite.com/privkey.pem;

# Test SSL
sudo nginx -t

# Reload
sudo systemctl reload nginx

# Verify SSL works
curl -I https://mysite.com

# Check certificate from browser
openssl s_client -connect mysite.com:443
```

### Common Certificate Problems
```bash
# Certificate not found
ls -la /etc/ssl/certs/

# Permissions issue
sudo chmod 644 /etc/ssl/certs/mycert.crt
sudo chmod 600 /etc/ssl/private/mycert.key

# Intermediate certificate missing
# Append intermediate to certificate file
cat /etc/ssl/certs/intermediate.crt >> /etc/ssl/certs/mycert.crt

# Expired certificate warning in logs
# Check renewal worked:
sudo certbot certificates

# Manual renewal if automatic fails
sudo certbot renew --manual
```

## Database Connectivity

### Test Database Connection
```bash
# Test MySQL/MariaDB
mysql -h dbhost -u dbuser -p dbname
mysql -h 192.168.1.50 -u webapp -p webdb

# Test PostgreSQL
psql -h dbhost -U dbuser -d dbname
psql -h 192.168.1.50 -U webapp webdb

# Test MongoDB
mongosh --host dbhost --authenticationDatabase admin -u dbuser -p
mongosh mongodb://dbuser:dbpass@dbhost:27017/dbname

# Test SQLite
sqlite3 /var/lib/app/database.db ".tables"
```

### Diagnose Connectivity Issues
```bash
# Verify database is running
sudo systemctl status mysql
sudo systemctl status postgresql

# Check database is listening
sudo ss -tulpn | grep 3306  # MySQL
sudo ss -tulpn | grep 5432  # PostgreSQL

# Test network connectivity
telnet dbhost 3306
telnet dbhost 5432

# Check hostname resolution
nslookup dbhost
dig dbhost

# Test from application host
nc -zv dbhost 3306
```

### Database User and Permissions
```bash
# Check database user exists (MySQL)
mysql -u root -p -e "SELECT user, host FROM mysql.user;"

# Create database user
mysql -u root -p -e "CREATE USER 'webapp'@'192.168.1.100' IDENTIFIED BY 'password';"

# Grant permissions
mysql -u root -p -e "GRANT SELECT,INSERT,UPDATE,DELETE ON webdb.* TO 'webapp'@'192.168.1.100';"

# Reload privileges
mysql -u root -p -e "FLUSH PRIVILEGES;"

# Check permissions
mysql -u root -p -e "SHOW GRANTS FOR 'webapp'@'192.168.1.100';"
```

### Connection Pooling and Limits
```bash
# Check max connections (MySQL)
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"

# Increase if needed
mysql -u root -p -e "SET GLOBAL max_connections = 500;"

# Make permanent
echo "max_connections = 500" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Check current connections
mysql -u root -p -e "SHOW PROCESSLIST;"
```

## Application Debugging

### View Application Logs
```bash
# Follow logs in real-time
sudo journalctl -u appname -f

# View last 100 lines
sudo journalctl -u appname -n 100

# View logs since boot
sudo journalctl -u appname -b

# Filter by priority
sudo journalctl -u appname -p err

# Search in logs
sudo journalctl -u appname | grep -i error
```

### Application Performance
```bash
# Monitor resource usage during execution
top -p PID

# Trace system calls
sudo strace -p PID

# Profile CPU usage
sudo perf top -p PID

# Monitor file I/O
sudo iotop -p PID

# View open files
lsof -p PID
```

### Application Configuration
```bash
# Verify config file exists
ls -la /etc/appname/config.conf

# Check config syntax if possible
appname --validate-config

# Check environment variables
env | grep -i appname

# Test config with verbose mode
appname -v -c /etc/appname/config.conf
```

## Troubleshooting

### Issue: Service starts but connections refused
**Steps:**
1. Verify service is actually running: `sudo systemctl status servicename`
2. Check it's listening on correct port: `sudo ss -tulpn | grep servicename`
3. Check firewall allows port: `sudo ufw status verbose`
4. Test locally: `curl localhost:PORT` or `telnet localhost PORT`
5. Check service logs for errors: `sudo journalctl -u servicename -f`

### Issue: Docker container exits immediately
**Steps:**
1. Check logs: `docker logs containername`
2. Check entrypoint/command is valid: `docker inspect --format='{{.Config.Entrypoint}}'`
3. Ensure all dependencies installed in image
4. Check required config files are mounted
5. Try interactive shell: `docker run -it imagename /bin/bash`

### Issue: Application can't reach database
**Steps:**
1. Verify database is running: `sudo systemctl status mysql`
2. Check database is listening: `sudo ss -tulpn | grep 3306`
3. Test connectivity: `mysql -h dbhost -u dbuser -p`
4. Verify user has permissions: Check GRANT statements
5. Check firewall allows database port
6. Verify hostname resolves: `nslookup dbhost`

### Issue: SSL certificate errors in browser
**Steps:**
1. Check cert is valid: `openssl x509 -in /path/to/cert -text`
2. Check cert not expired: `openssl x509 -in /path/to/cert -noout -dates`
3. Verify hostname matches cert: `openssl s_client -connect mysite.com:443`
4. Check intermediate certificate included
5. Verify cert loaded in web server: `grep ssl_certificate /etc/nginx/conf.d/*`

## Best Practices

- Keep detailed service logs for at least 30 days
- Monitor service health with systemd timers and monitoring tools
- Document all custom services and their dependencies
- Test service startup sequence after configuration changes
- Use separate system users for services with restricted permissions
- Implement automated certificate renewal well before expiration
- Log all connection attempts to database for troubleshooting
- Keep application logs separate from system logs
- Use structured logging format for easier analysis

---

✅ Service troubleshooting guide complete - identify and fix service issues systematically
