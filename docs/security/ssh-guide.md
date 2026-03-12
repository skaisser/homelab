# 🔐 SSH Guide #ssh #security #git #encryption

A comprehensive guide to SSH key management, secure connections, and Git integration.

## 📋 Table of Contents
- [Key Generation](#key-generation)
- [Server Configuration](#server-configuration)
- [Client Configuration](#client-configuration)
- [GitHub Integration](#github-integration)
- [Best Practices](#best-practices)

## 🔑 Key Generation

### Modern SSH Key Creation
```bash
# Generate Ed25519 key (recommended for modern systems)
ssh-keygen -t ed25519 -C \"your_email@example.com\"

# For legacy systems that don't support Ed25519
ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\"

# Generate with custom filename
ssh-keygen -t ed25519 -f ~/.ssh/custom_key -C \"your_email@example.com\"
```

### Key Management
```bash
# List existing keys
ls -la ~/.ssh/

# Check key fingerprint
ssh-keygen -l -f ~/.ssh/id_ed25519

# Convert key format (if needed)
ssh-keygen -p -f ~/.ssh/id_ed25519 -m PEM
```

## 🖥️ Server Configuration

### Adding Keys to Server

1. **Using ssh-copy-id (Recommended)**
```bash
# Copy key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# Copy key with custom port
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 user@server
```

2. **Manual Method**
```bash
# Copy public key content
cat ~/.ssh/id_ed25519.pub

# On server: create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# On server: add key to authorized_keys
echo \"public_key_content\" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Server Security Configuration
```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Recommended settings
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Protocol 2
Port 2222  # Custom port for better security

# Restart SSH service
sudo systemctl restart sshd
```

## 👥 Client Configuration

### SSH Config File
```bash
# Create/edit SSH config
nano ~/.ssh/config

# Example configuration
Host server-nickname
    HostName server.example.com
    User username
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    ForwardAgent no

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_ed25519
    AddKeysToAgent yes
```

### SSH Agent Management
```bash
# Start SSH agent
eval \"$(ssh-agent -s)\"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# List added keys
ssh-add -l

# Remove specific key
ssh-add -d ~/.ssh/id_ed25519

# Remove all keys
ssh-add -D
```

## 🌐 GitHub Integration

### Setting up GitHub SSH Keys
```bash
# Generate GitHub-specific key
ssh-keygen -t ed25519 -f ~/.ssh/github_ed25519 -C \"your_github_email@example.com\"

# Copy public key
cat ~/.ssh/github_ed25519.pub
```

Then add the key to GitHub:
1. Go to GitHub → Settings → SSH and GPG keys
2. Click \"New SSH key\"
3. Paste your public key

### Signing Git Commits with SSH
```bash
# Configure Git to use SSH key for signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/github_ed25519.pub

# Enable commit signing by default
git config --global commit.gpgsign true

# Make a signed commit
git commit -S -m \"Signed commit message\"

# Verify signed commit
git verify-commit HEAD
```

### Testing GitHub Connection
```bash
# Test SSH connection
ssh -T git@github.com

# Clone repository using SSH
git clone git@github.com:username/repository.git
```

## 🔒 Best Practices

1. **Key Security**
   - Use Ed25519 keys (modern, secure, fast)
   - Protect private keys with strong passphrase
   - Never share private keys
   - Keep separate keys for different purposes

2. **Server Security**
   - Disable password authentication
   - Use non-standard ports
   - Limit login attempts
   - Keep software updated
   - Use fail2ban for protection

3. **Client Security**
   - Use SSH config file
   - Forward agent selectively
   - Use different keys for different services
   - Regular key rotation

4. **Git Security**
   - Always sign important commits
   - Use separate keys for signing
   - Verify signatures on pulls
   - Keep signing keys secure

## 🛠️ Troubleshooting

### Common Issues
```bash
# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config

# Debug connection
ssh -v user@server

# Test key permissions
ssh -T git@github.com -i ~/.ssh/github_ed25519
```

### Key Conversion
```bash
# Convert OpenSSH to PEM
ssh-keygen -p -m PEM -f ~/.ssh/id_ed25519

# Convert PEM to OpenSSH
ssh-keygen -p -m RFC4716 -f ~/.ssh/id_ed25519
```

## 📚 Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [SSH Security Best Practices](https://www.ssh.com/ssh/key/best-practices)

> 💡 **Pro Tip**: Use `ssh-keygen -t ed25519` for new keys as it provides the best balance of security and performance. RSA-4096 is a good fallback for legacy systems.
