# 📧 Email Server Configuration #self-hosted #email #mail #docker-mailserver

Self-hosted email is possible but complex. This guide covers practical setup with docker-mailserver and explains why most homelabbers use external email.

## Table of Contents
1. [Important Disclaimer](#important-disclaimer)
2. [Complexity Reality Check](#complexity-reality-check)
3. [Docker Mailserver Overview](#docker-mailserver-overview)
4. [Docker Compose Deployment](#docker-compose-deployment)
5. [DNS Records (MX, SPF, DKIM, DMARC)](#dns-records-mx-spf-dkim-dmarc)
6. [Basic Configuration](#basic-configuration)
7. [SSL/TLS Setup](#ssltls-setup)
8. [Creating Accounts](#creating-accounts)
9. [Testing with swaks](#testing-with-swaks)
10. [Spam Filtering](#spam-filtering)
11. [Why Most Use External Email](#why-most-use-external-email)
12. [Troubleshooting](#troubleshooting)
13. [Additional Resources](#additional-resources)

## Important Disclaimer

**WARNING**: Email hosting requires:
- Static public IP address (mandatory)
- Proper DNS delegation
- SMTP authentication and encryption
- Continuous monitoring and maintenance
- Spam filtering expertise
- Legal understanding of email regulations

**Not suitable for:**
- Residential ISPs (dynamic IP, port 25 blocked)
- Small teams (requires constant attention)
- Business-critical email (use professional services)

Most successful homelabbers use:
- Gmail/Outlook for personal email
- Mailgun/SendGrid for application notifications
- AWS SES for transactional email

---

## Complexity Reality Check

### Setup Time
- Initial deployment: 2-4 hours
- DNS configuration: 1-2 hours
- Troubleshooting: 4-8 hours (first attempt)
- **Total: 8-14 hours minimum**

### Ongoing Maintenance
- Spam filtering: 2-3 hours/week
- Monitoring: 30 minutes/day
- Security updates: 2-3 hours/month
- Backup/recovery: 1 hour/week
- **Total: 5-8 hours/week**

### Common Issues
- IP blacklisted on RBL (takes weeks to remove)
- Spam overwhelms mailbox
- Backup grows to terabytes
- Email delivery failures (especially to Gmail)
- Spam phishing attacks using your domain

### When It Makes Sense
- Dedicated server with static IP
- Full control needed for compliance
- Low email volume (<10 users)
- Experienced sysadmin managing it
- Acceptable downtime (no redundancy)

---

## Docker Mailserver Overview

docker-mailserver is the most practical self-hosted solution.

**Advantages:**
- Postfix + Dovecot + SpamAssassin bundled
- Let's Encrypt support
- Account management via CLI
- Reasonable documentation
- Community maintained

**Limitations:**
- No webmail interface (use Roundcube separately)
- Limited to single server (no clustering)
- Requires Linux knowledge
- No automatic spam learning
- Support is community-based

## Docker Compose Deployment

### Prerequisites

```bash
# Static IP required
# Check if ISP blocks port 25
curl -X SMTP -v smtp.example.com:25

# DNS access to add records
# Dedicated domain for mail (not subdomain)
```

### Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  mailserver:
    image: ghcr.io/docker-mailserver/docker-mailserver:latest
    container_name: mailserver
    hostname: mail.example.com
    domainname: example.com
    ports:
      - "25:25"      # SMTP (incoming)
      - "465:465"    # SMTPS
      - "587:587"    # Submission (authenticated)
      - "110:110"    # POP3
      - "143:143"    # IMAP
      - "993:993"    # IMAPS
      - "995:995"    # POP3S
    environment:
      - ENABLE_CLAMAV=0
      - ENABLE_FAIL2BAN=1
      - ENABLE_MANAGESIEVE=1
      - SPOOF_PROTECTION=1
      - ENABLE_POP3=1
      - SSL_TYPE=letsencrypt
      - SSL_DOMAIN=mail.example.com
      - POSTSCREEN_ACTION=enforce
      - TZ=America/New_York
    volumes:
      - /opt/mailserver/mail-data:/var/mail
      - /opt/mailserver/mail-state:/var/mail-state
      - /opt/mailserver/mail-logs:/var/log/mail
      - /opt/mailserver/config:/tmp/docker-mailserver
      - /opt/mailserver/letsencrypt:/etc/letsencrypt
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    networks:
      - homelab
    cap_add:
      - NET_ADMIN

networks:
  homelab:
    external: true
```

### Initialize

```bash
# Create directories
mkdir -p /opt/mailserver/{mail-data,mail-state,mail-logs,config,letsencrypt}
sudo chown -R 1000:1000 /opt/mailserver

# Create config files
touch /opt/mailserver/config/postfix-accounts.cf
touch /opt/mailserver/config/postfix-virtual.cf
touch /opt/mailserver/config/dovecot.cf

# Start mail server
docker-compose up -d

# Wait for Let's Encrypt certificate
sleep 60

# Verify status
docker-compose logs mailserver | grep -i "certificates"
```

## DNS Records (MX, SPF, DKIM, DMARC)

DNS configuration determines email deliverability.

### MX Record (Mail Exchange)

Points domain to mail server:

```
@ (or mail.example.com)  MX  10  mail.example.com
```

Verify:

```bash
nslookup -query=MX example.com
# Should return: example.com mail exchanger = 10 mail.example.com
```

### SPF Record (Sender Policy Framework)

Prevents spoofing:

```
v=spf1 mx ~all

# Explanation:
# v=spf1           - SPF version 1
# mx               - Allow MX record
# ~all             - Soft fail others (- for hard fail)
```

Add to DNS as TXT record:

```bash
nslookup -query=TXT example.com SPF
```

### DKIM (DomainKeys Identified Mail)

Digitally sign outgoing emails:

```bash
# Generate DKIM keys (in mailserver)
docker-compose exec mailserver setup email add example.com

# View public key
cat /opt/mailserver/config/opendkim/keys/example.com/mail.txt

# Output format:
# mail._domainkey  IN  TXT  "v=DKIM1; k=rsa; p=MIGfMA0BgkqhkiG9w0..."
```

Add to DNS as TXT record at: `mail._domainkey.example.com`

```bash
# Verify
nslookup mail._domainkey.example.com TXT
```

### DMARC (Domain Message Authentication Reporting)

Policy for SPF/DKIM failures:

```
v=DMARC1; p=quarantine; rua=mailto:admin@example.com; ruf=mailto:admin@example.com

# Explanation:
# v=DMARC1             - DMARC version
# p=quarantine         - Quarantine failing emails
# rua=mailto:          - Aggregate report address
# ruf=mailto:          - Forensic report address
```

Add to DNS at: `_dmarc.example.com` as TXT record

Verify all records:

```bash
# Complete check
for record in MX SPF DKIM DMARC; do
  echo "=== $record ==="
  case $record in
    MX) nslookup -query=MX example.com ;;
    SPF) nslookup -query=TXT example.com ;;
    DKIM) nslookup mail._domainkey.example.com TXT ;;
    DMARC) nslookup _dmarc.example.com TXT ;;
  esac
done
```

## Basic Configuration

### Create Mail Account

```bash
# Add user and mailbox
docker-compose exec mailserver setup email add user@example.com securePassword123

# Verify
docker-compose exec mailserver setup email list
```

### Configure Quotas

Per-user storage limits:

```bash
# Set 2GB quota
docker-compose exec mailserver setup quota set user@example.com 2G

# View quotas
docker-compose exec mailserver setup quota list
```

### Aliases and Forwards

Forward emails to multiple addresses:

```bash
# Create alias (multiple recipients)
docker-compose exec mailserver setup alias add admin@example.com user1@example.com user2@example.com

# Create forward (single recipient)
docker-compose exec mailserver setup email add forward@example.com forward_password
echo "forward@example.com user@gmail.com" >> /opt/mailserver/config/postfix-virtual.cf
```

## SSL/TLS Setup

Let's Encrypt automatically configured via docker-compose.

### Manual Certificate Placement

If not using Let's Encrypt:

```bash
# Copy certificates
cp /path/to/cert.pem /opt/mailserver/letsencrypt/live/mail.example.com/fullchain.pem
cp /path/to/key.pem /opt/mailserver/letsencrypt/live/mail.example.com/privkey.pem

docker-compose exec mailserver chown mail:mail /etc/letsencrypt/live/mail.example.com/*
docker-compose restart mailserver
```

### Verify TLS

```bash
# Test SMTP TLS
openssl s_client -connect mail.example.com:587 -starttls smtp

# Test IMAP TLS
openssl s_client -connect mail.example.com:993

# Both should show certificate details
```

## Creating Accounts

### Via CLI

```bash
# Add account
docker-compose exec mailserver setup email add john@example.com johnPassword123

# Delete account
docker-compose exec mailserver setup email delete john@example.com

# Change password
docker-compose exec mailserver setup email update john@example.com newPassword456

# List all accounts
docker-compose exec mailserver setup email list
```

### User Configuration File

Manually edit `/opt/mailserver/config/postfix-accounts.cf`:

```
john@example.com|$6$hash$verylonghash
mary@example.com|$6$hash$anotherlonghash
```

Passwords must be hashed:

```bash
# Generate hash
docker-compose exec mailserver doveadm pw -s SHA512-CRYPT -p plaintext
```

## Testing with swaks

Test mail delivery:

```bash
# Install swaks (Perl-based SMTP testing tool)
sudo apt-get install swaks

# Send test email via SMTP
swaks --to user@example.com \
      --from test@example.com \
      --server mail.example.com \
      --auth \
      --auth-user test@example.com \
      --auth-password password \
      --tlsc

# Options:
# --tlsc          - Use TLS
# --header-X-Test - Add custom header
# -body           - Specify message body
```

Monitor delivery:

```bash
# Watch mail logs
docker-compose exec mailserver tail -f /var/log/mail/mail.log

# Check Postfix queue
docker-compose exec mailserver postqueue -p

# Check spam score (SpamAssassin)
docker-compose exec mailserver spamc -t < /tmp/email.eml
```

## Spam Filtering

### SpamAssassin Configuration

Default enabled. Adjust sensitivity:

```bash
# View configuration
docker-compose exec mailserver cat /etc/spamassassin/local.cf

# Adjust score threshold (default 5.0)
echo "required_score 4.0" >> /opt/mailserver/config/spamassassin/local.cf

docker-compose restart mailserver
```

### Enable Bayes Learning

Train spam filter:

```bash
# Mark as spam
sa-learn --spam /path/to/spam/folder

# Mark as ham
sa-learn --ham /path/to/legitimate/folder

# View statistics
sa-learn --dump magic
```

### Fail2Ban Integration

Auto-blocks attackers:

```bash
# View banned IPs
docker-compose exec mailserver fail2ban-client status postfix

# Unban IP
docker-compose exec mailserver fail2ban-client set postfix unbanip 192.168.1.100
```

## Why Most Use External Email

### Problems with Self-Hosted

1. **IP Reputation**: Home ISPs have poor reputation
   - Gmail, Outlook default reject home IPs
   - RBL blacklisting takes weeks to remove
   - Delivery rate: ~60% vs 99% with external

2. **Spam Management**
   - Spam increases exponentially
   - SpamAssassin requires constant tuning
   - False positive rate: 5-10%
   - Spam learning requires expertise

3. **Maintenance Burden**
   - 24/7 monitoring required
   - Certificate renewal failures
   - Database corruption risks
   - Security patches critical

4. **Compliance Issues**
   - GDPR data retention rules
   - Business email disclosures
   - Record retention policies
   - No audit trail

5. **No Redundancy**
   - Single failure = email down
   - No failover capability
   - Backup recovery manual process

### Better Alternatives

**Personal Use:**
- Gmail: Free, reliable, spam filtering excellent
- ProtonMail: Encrypted, privacy-focused
- Zoho Mail: Affordable, many features

**Team Use:**
- Google Workspace: $6-14/user/month
- Microsoft 365: $6-12/user/month
- Zoho Workplace: $1-3/user/month

**Transactional Email:**
- Mailgun: $0.50/1000 emails
- SendGrid: $9.95+/month
- AWS SES: $0.10 per 1000 emails

**Exception Cases:**
- Compliance required (healthcare, finance)
- Large team (100+ users)
- Dedicated email server
- Experienced email administrator

## Troubleshooting

### Email delivery failing
```bash
# Check MX records
nslookup -query=MX example.com

# Check SPF/DKIM/DMARC
nslookup -query=TXT example.com

# Monitor logs
docker-compose logs -f mailserver | grep -i "REJECT\|ACCEPT"
```

### Can't connect via IMAP
```bash
# Test IMAP port
telnet localhost 143

# Check certificate
openssl s_client -connect localhost:993

# Restart Dovecot
docker-compose restart mailserver
```

### High spam rate
```bash
# Check SpamAssassin score
echo "Test email body" | spamc -t

# Retrain Bayes
sa-learn --force-expire

# Increase threshold temporarily
echo "required_score 8.0" > /opt/mailserver/config/spamassassin/local.cf
```

### Bounced emails in queue
```bash
# Check postfix queue
docker-compose exec mailserver postqueue -p

# View bounce messages
docker-compose exec mailserver postcat -q messageID

# Delete old messages
docker-compose exec mailserver postsuper -d ALL deferred
```

## Best Practices

1. **Don't do it**: Use Gmail/workspace instead
2. **If you must**:
   - Dedicated static IP required
   - Detailed DNS setup essential
   - Daily monitoring mandatory
   - Weekly backup routine
   - Monthly security updates
   - Document everything

3. **Testing**:
   - Use MXToolbox to test
   - Check IP reputation regularly
   - Monitor delivery logs daily

## Additional Resources

- [docker-mailserver Documentation](https://docker-mailserver.github.io/docker-mailserver/latest/)
- [SPF/DKIM/DMARC Guide](https://mxtoolbox.com/dkim.aspx)
- [Postfix Configuration](http://www.postfix.org/documentation.html)
- [Dovecot Documentation](https://doc.dovecot.org)
- [MXToolbox Utilities](https://mxtoolbox.com)

---

✅ **Email server configured—but seriously, use Gmail instead!**
