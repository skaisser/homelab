# 🤖 Automation with Ansible #automation #ansible #configuration-management #devops

Ansible is an agentless configuration management tool that allows you to manage multiple servers from a single control machine. Unlike other tools, Ansible doesn't require installing agents on target servers—it uses SSH. For homelabs, Ansible simplifies repetitive tasks: applying security patches, deploying services, managing users, and configuring Docker containers across multiple machines. This guide covers Ansible fundamentals, practical playbooks for homelab scenarios, and tips for managing a fleet of servers.

## Table of Contents

- [Why Ansible for Homelab](#why-ansible-for-homelab)
- [Installation](#installation)
- [Inventory File Setup](#inventory-file-setup)
- [SSH Key Configuration](#ssh-key-configuration)
- [First Playbook](#first-playbook)
- [Common Modules](#common-modules)
- [Roles and Directory Structure](#roles-and-directory-structure)
- [Variables and Vault](#variables-and-vault)
- [Practical Playbooks](#practical-playbooks)
- [Ansible-Pull](#ansible-pull)
- [Managing Fleet](#managing-fleet)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Why Ansible for Homelab

Running commands manually on each server is tedious and error-prone. Ansible lets you:
- Define infrastructure as code
- Apply changes consistently across multiple servers
- Quickly set up new machines
- Audit what's configured and why
- Recover quickly from failures (replay playbooks)

Compared to alternatives:
- **Terraform**: Infrastructure provisioning (VMs, cloud resources)
- **Chef/Puppet**: Heavy, require agent installation
- **Ansible**: Lightweight, agentless, SSH-based, great for configuration management

For a homelab with 2-10 servers, Ansible is ideal.

## Installation

Install Ansible on your control machine (the computer from which you manage other servers):

```bash
#!/usr/bin/env bash
set -euo pipefail

# On Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y ansible

# Verify installation
ansible --version

# On macOS
brew install ansible
```

For the managed nodes (servers you're controlling), ensure:
- SSH is running
- Python 3 is installed (Ansible uses Python to run tasks on remote hosts)

```bash
#!/usr/bin/env bash
set -euo pipefail

# On each managed node, ensure Python is installed
sudo apt-get update
sudo apt-get install -y python3 python3-pip
```

## Inventory File Setup

Ansible uses an inventory file to know which servers to manage. Create `~/ansible/inventory.ini`:

```ini
[all:vars]
# Variables applicable to all hosts
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/homelab_key

[webservers]
web01.homelab.local ansible_host=192.168.1.10
web02.homelab.local ansible_host=192.168.1.11

[databases]
db01.homelab.local ansible_host=192.168.1.20

[storage]
nas01.homelab.local ansible_host=192.168.1.30

[all_servers:children]
webservers
databases
storage
```

Or in YAML format (`inventory.yml`):

```yaml
all:
  children:
    webservers:
      hosts:
        web01.homelab.local:
          ansible_host: 192.168.1.10
        web02.homelab.local:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db01.homelab.local:
          ansible_host: 192.168.1.20
    storage:
      hosts:
        nas01.homelab.local:
          ansible_host: 192.168.1.30
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/homelab_key
```

Test inventory:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/ansible

# List all hosts
ansible-inventory -i inventory.ini --list

# Ping all hosts (tests connectivity)
ansible -i inventory.ini all -m ping
```

## SSH Key Configuration

Ansible communicates via SSH. Set up key-based authentication:

On your control machine, generate an SSH key (if you don't have one):

```bash
#!/usr/bin/env bash
set -euo pipefail

ssh-keygen -t ed25519 -f ~/.ssh/homelab_key -N ""  # Empty passphrase for automation
```

Copy the public key to each managed node:

```bash
#!/usr/bin/env bash
set -euo pipefail

for host in 192.168.1.10 192.168.1.11 192.168.1.20 192.168.1.30; do
  ssh-copy-id -i ~/.ssh/homelab_key.pub -p 22 "ubuntu@${host}"
done
```

Verify SSH access:

```bash
#!/usr/bin/env bash
set -euo pipefail

ssh -i ~/.ssh/homelab_key ubuntu@192.168.1.10 "echo 'SSH works!'"
```

## First Playbook

A playbook is a YAML file with a list of tasks. Create `~/ansible/playbooks/update-all.yml`:

```yaml
---
- name: Update all servers
  hosts: all
  become: yes  # Run with sudo
  gather_facts: yes  # Collect system info

  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600  # Cache for 1 hour

    - name: Upgrade all packages
      apt:
        upgrade: dist
        autoremove: yes
        autoclean: yes

    - name: Notify when done
      debug:
        msg: "Server {{ inventory_hostname }} updated successfully"
```

Run the playbook:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/ansible

# Dry-run (shows what would happen without making changes)
ansible-playbook -i inventory.ini playbooks/update-all.yml --check

# Execute for real
ansible-playbook -i inventory.ini playbooks/update-all.yml --ask-become-pass
```

The `--ask-become-pass` prompts for the sudo password. Alternatively, configure passwordless sudo on your target servers.

## Common Modules

Ansible modules are plugins that perform tasks. Common ones:

**apt**: Package management

```yaml
- name: Install packages
  apt:
    name: ["docker.io", "git", "curl"]
    state: present

- name: Remove a package
  apt:
    name: apache2
    state: absent
```

**copy**: Copy files

```yaml
- name: Copy config file
  copy:
    src: ./configs/app.conf
    dest: /etc/app.conf
    owner: root
    group: root
    mode: '0644'
```

**template**: Template files (supports Jinja2 variables)

```yaml
- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart nginx
```

**service**: Manage systemd services

```yaml
- name: Start and enable Docker
  service:
    name: docker
    state: started
    enabled: yes
```

**shell/command**: Run arbitrary commands

```yaml
- name: Run a shell command
  shell: |
    set -euo pipefail
    echo "Hello from {{ inventory_hostname }}"

- name: Run a command (simpler, preferred when no piping needed)
  command: /usr/local/bin/backup-database
```

**user**: Manage user accounts

```yaml
- name: Create a user
  user:
    name: appuser
    groups: docker
    shell: /bin/bash
    createhome: yes
    home: /home/appuser
```

**docker_container**: Manage Docker containers

```yaml
- name: Run a Docker container
  docker_container:
    name: nginx
    image: nginx:latest
    ports:
      - "80:80"
    state: started
```

**file**: Manage file and directory permissions

```yaml
- name: Create a directory
  file:
    path: /var/app/data
    state: directory
    owner: appuser
    group: appuser
    mode: '0755'

- name: Create a symlink
  file:
    src: /opt/app/v1.0
    dest: /opt/app/current
    state: link
```

**lineinfile**: Modify files line-by-line

```yaml
- name: Add line to config
  lineinfile:
    path: /etc/config.conf
    line: "new_option = true"
    state: present
```

**handlers**: Respond to changes (e.g., restart services when configs change)

```yaml
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: restart nginx  # Triggers handler

handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

## Roles and Directory Structure

Roles organize tasks, variables, and files into reusable units. Structure:

```
~/ansible/
├── inventory.ini
├── ansible.cfg
├── playbooks/
│   ├── site.yml
│   └── deploy.yml
└── roles/
    ├── common/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   ├── vars/
    │   │   └── main.yml
    │   ├── defaults/
    │   │   └── main.yml
    │   ├── files/
    │   └── templates/
    ├── docker/
    │   ├── tasks/
    │   │   └── main.yml
    │   └── defaults/
    │       └── main.yml
    └── monitoring/
        ├── tasks/
        │   └── main.yml
        └── templates/
            └── prometheus.yml.j2
```

Create a role:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/ansible

# Generate role structure (Ansible creates it)
ansible-galaxy init roles/common
```

Define the role in `roles/common/tasks/main.yml`:

```yaml
---
- name: Update package cache
  apt:
    update_cache: yes

- name: Install base packages
  apt:
    name: ["git", "curl", "vim", "htop"]
    state: present

- name: Configure SSH (disable root login)
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?PermitRootLogin'
    line: 'PermitRootLogin no'
  notify: restart sshd

- name: Set hostname
  hostname:
    name: "{{ inventory_hostname }}"
```

Use the role in a playbook (`playbooks/site.yml`):

```yaml
---
- name: Configure all servers
  hosts: all
  become: yes

  roles:
    - common
    - docker
```

Run the playbook:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/ansible
ansible-playbook -i inventory.ini playbooks/site.yml
```

## Variables and Vault

Variables make playbooks flexible. Define them at multiple levels:

**Inventory variables** (`inventory.ini`):

```ini
[webservers]
web01.homelab.local env=prod
web02.homelab.local env=staging
```

**Playbook variables** (`playbooks/deploy.yml`):

```yaml
---
- name: Deploy application
  hosts: webservers
  vars:
    app_version: "1.2.3"
    app_port: 8080
  tasks:
    - name: Deploy version {{ app_version }}
      debug:
        msg: "Deploying {{ app_version }} to port {{ app_port }}"
```

**Role variables** (`roles/myapp/defaults/main.yml`):

```yaml
---
app_user: appuser
app_home: /opt/myapp
app_config_file: /etc/myapp.conf
```

**Host/group variables**:

Create `host_vars/web01.homelab.local.yml`:

```yaml
---
node_exporter_port: 9100
custom_fact: "special-value-for-web01"
```

**Vault**: Encrypt sensitive variables

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ~/ansible

# Create encrypted vars file
ansible-vault create group_vars/all/vault.yml

# Type your secrets (e.g., passwords, API keys):
# db_password: super-secret-password
# api_token: abc123xyz
```

Use vault in playbooks:

```yaml
tasks:
  - name: Configure database
    shell: |
      mysql -u root -p{{ db_password }} -e "CREATE USER 'app'@'localhost';"
    vars:
      db_password: "{{ vault_db_password }}"
```

Run playbook with vault:

```bash
#!/usr/bin/env bash
set -euo pipefail

ansible-playbook -i inventory.ini playbooks/deploy.yml --ask-vault-pass
```

Or store vault password in a file (more automation-friendly, keep secure):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Create a vault password file
echo "my-vault-password" > ~/.ansible/vault-pass.txt
chmod 600 ~/.ansible/vault-pass.txt

# Reference in ansible.cfg
cat << 'EOF' >> ansible.cfg
[defaults]
vault_password_file = ~/.ansible/vault-pass.txt
EOF
```

## Practical Playbooks

### Initial Server Setup

Create `playbooks/initial-setup.yml`:

```yaml
---
- name: Initial server setup
  hosts: all
  become: yes

  tasks:
    - name: Update system
      apt:
        update_cache: yes
        upgrade: dist

    - name: Install base packages
      apt:
        name: ["build-essential", "curl", "git", "htop", "vim", "python3-pip"]
        state: present

    - name: Create application user
      user:
        name: appuser
        groups: sudo
        shell: /bin/bash
        createhome: yes

    - name: Configure SSH (disable root login)
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: restart sshd

    - name: Configure firewall
      apt:
        name: ufw
        state: present

    - name: Enable UFW
      ufw:
        state: enabled
        policy: deny
        direction: incoming

    - name: Allow SSH
      ufw:
        rule: allow
        port: '22'
        proto: tcp

  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

Run it:

```bash
#!/usr/bin/env bash
set -euo pipefail

ansible-playbook -i inventory.ini playbooks/initial-setup.yml --ask-become-pass
```

### Docker Installation

Create `roles/docker/tasks/main.yml`:

```yaml
---
- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present

- name: Install Docker
  apt:
    name: ["docker-ce", "docker-ce-cli", "containerd.io", "docker-compose-plugin"]
    state: present
    update_cache: yes

- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes

- name: Enable Docker service
  service:
    name: docker
    state: started
    enabled: yes

- name: Test Docker installation
  shell: docker run --rm hello-world
  changed_when: false
```

### User Management

Create `playbooks/manage-users.yml`:

```yaml
---
- name: Manage users across homelab
  hosts: all
  become: yes

  vars:
    users:
      - name: john
        groups: [sudo, docker]
        shell: /bin/bash
      - name: jane
        groups: [docker]
        shell: /bin/bash

  tasks:
    - name: Create or update users
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups | join(',') }}"
        shell: "{{ item.shell }}"
        createhome: yes
        state: present
      loop: "{{ users }}"

    - name: Ensure SSH directory exists
      file:
        path: "/home/{{ item.name }}/.ssh"
        state: directory
        owner: "{{ item.name }}"
        group: "{{ item.name }}"
        mode: '0700'
      loop: "{{ users }}"
```

## Ansible-Pull

Ansible-pull inverts the traditional model: instead of pushing from a control machine, pull from a central repository. Useful for servers managing themselves.

Set up a GitHub repository with your playbooks and create a cron job on each server:

```bash
#!/usr/bin/env bash
set -euo pipefail

# On each managed server, set up ansible-pull
sudo apt-get install -y ansible git

# Create a cron job to run every 30 minutes
sudo crontab -e
# Add: */30 * * * * /usr/bin/ansible-pull -U https://github.com/your-user/homelab-ansible.git -d /opt/homelab-ansible main.yml >> /var/log/ansible-pull.log 2>&1
```

Repository structure:

```
homelab-ansible/
├── main.yml
├── roles/
│   ├── common/
│   └── docker/
└── group_vars/
    └── all.yml
```

Benefits:
- Decentralized: each server self-updates
- No control machine required
- Great for distributed homelabs or when control machine is down

## Managing Fleet

**Running tasks on specific groups**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Run on webservers only
ansible-playbook -i inventory.ini playbooks/deploy.yml -l webservers

# Run on a specific host
ansible-playbook -i inventory.ini playbooks/deploy.yml -l web01.homelab.local

# Run on multiple groups
ansible-playbook -i inventory.ini playbooks/deploy.yml -l "webservers,databases"

# Exclude a host
ansible-playbook -i inventory.ini playbooks/deploy.yml --skip-hosts db01.homelab.local
```

**Ad-hoc commands** (for quick tasks, no playbook needed):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check uptime on all servers
ansible -i inventory.ini all -m command -a "uptime"

# Restart Docker on webservers
ansible -i inventory.ini webservers -m service -a "name=docker state=restarted" -b

# Copy a file
ansible -i inventory.ini all -m copy -a "src=/tmp/file.txt dest=/tmp/ owner=root group=root mode=0644" -b
```

**Serial execution** (run on one server at a time):

```yaml
---
- name: Rolling deployment
  hosts: webservers
  serial: 1  # One server at a time
  tasks:
    - name: Deploy application
      shell: /opt/deploy.sh
```

## Troubleshooting

**SSH connection failed:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test SSH manually
ssh -i ~/.ssh/homelab_key -vvv ubuntu@192.168.1.10

# Check Ansible SSH options
ansible -i inventory.ini all -m ping -vvv
```

**Module not found:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check installed modules
ansible-doc -l | grep docker

# Install missing modules via ansible-galaxy
ansible-galaxy collection install community.docker
```

**Syntax errors in YAML:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate playbook syntax
ansible-playbook playbooks/site.yml --syntax-check
```

**Handlers not running:**

Ensure notify name matches handler name exactly. Handlers only run if a task triggers them.

**Vault password issues:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# View encrypted content
ansible-vault view group_vars/all/vault.yml

# Re-encrypt if needed
ansible-vault rekey group_vars/all/vault.yml
```

## Best Practices

1. **Start simple**: Begin with a few playbooks, expand gradually.
2. **Use version control**: Commit all Ansible files to Git.
3. **Test on non-prod first**: Always run `--check` before executing on production servers.
4. **Use roles for reusability**: Avoid copy-pasting tasks.
5. **Document variables**: Comment variable purposes and defaults.
6. **Secure secrets**: Always use Vault for passwords and API keys.
7. **Log playbook runs**: Redirect output to a file for auditing.
8. **Idempotent tasks**: Ensure tasks can run multiple times safely (e.g., use `state: present` instead of `shell`).
9. **Limit privilege escalation**: Use `become: yes` only when necessary.
10. **Monitor drift**: Periodically run playbooks to detect and remediate configuration changes.

## Additional Resources

- [Ansible Official Documentation](https://docs.ansible.com/)
- [Ansible Galaxy (Community Roles)](https://galaxy.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Ansible Modules Reference](https://docs.ansible.com/ansible/latest/collections/index.html)
- [Ansible Testing Guide](https://docs.ansible.com/ansible/latest/dev_guide/developing_tested.html)

---

✅ Ansible automation configured for initial server setup, Docker installation, user management, and rolling deployments across your homelab fleet.
