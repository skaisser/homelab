# 🖥️ KVM/QEMU Virtualization Guide #kvm #qemu #virtualization #libvirt

KVM (Kernel-based Virtual Machine) is a powerful open-source hypervisor that turns Linux into a Type-1 hypervisor, allowing you to run multiple isolated virtual machines efficiently. Combined with QEMU for system emulation and libvirt for management, KVM provides production-grade virtualization at no cost. This guide covers installation, VM creation, management, and advanced features like GPU passthrough and live migration.

## Table of Contents

- [Understanding KVM vs Other Hypervisors](#understanding-kvm-vs-other-hypervisors)
- [Prerequisites and Installation](#prerequisites-and-installation)
- [Creating Your First Virtual Machine](#creating-your-first-virtual-machine)
- [Managing VMs with virsh](#managing-vms-with-virsh)
- [Disk Management and Storage](#disk-management-and-storage)
- [Networking Configuration](#networking-configuration)
- [GPU Passthrough Basics](#gpu-passthrough-basics)
- [Performance Tuning](#performance-tuning)
- [Live Migration](#live-migration)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Understanding KVM vs Other Hypervisors

KVM is excellent for homelabs because it's:
- **Free and open-source** with no licensing costs
- **Native to Linux** with minimal overhead
- **Feature-rich** supporting advanced capabilities (live migration, snapshots, GPU passthrough)
- **Flexible** with multiple management tools (virsh, virt-manager, Proxmox)

Use KVM when you need bare-metal hypervisor performance on Linux. Use Docker/LXC for containerized workloads instead.

## Prerequisites and Installation

### Check KVM Capability

Before installation, verify your CPU supports virtualization:

```bash
#!/bin/bash
set -euo pipefail

# Check for Intel VT-x or AMD-V
grep -E 'vmx|svm' /proc/cpuinfo | head -1

# Alternative check using lscpu
lscpu | grep -E 'Virtualization|Flags'

# If output shows vmx (Intel) or svm (AMD), you're good!
```

### Install KVM on Debian/Ubuntu

```bash
#!/bin/bash
set -euo pipefail

# Update package lists
sudo apt-get update

# Install KVM and related packages
sudo apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virtinst \
    virt-manager \
    virt-viewer

# Add current user to libvirt groups (then logout/login)
sudo usermod -aG libvirt "$(whoami)"
sudo usermod -aG kvm "$(whoami)"

# Start and enable libvirtd
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Verify installation
virsh list --all
```

## Creating Your First Virtual Machine

### Method 1: Using virt-install (Recommended for Automation)

```bash
#!/bin/bash
set -euo pipefail

# Set variables
VM_NAME="ubuntu-server-01"
RAM_MB=4096
VCPUS=2
DISK_SIZE=50
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
ISO_PATH="/var/lib/libvirt/isos/ubuntu-22.04-server-amd64.iso"

# Create a new VM with virt-install
virt-install \
    --name "$VM_NAME" \
    --memory "$RAM_MB" \
    --vcpus "$VCPUS" \
    --disk path="$DISK_PATH",size="$DISK_SIZE",format=qcow2 \
    --cdrom "$ISO_PATH" \
    --network bridge=virbr0,model=virtio \
    --graphics spice \
    --console pty,target_type=virtio \
    --noautoconsole

# Monitor installation
virt-viewer "$VM_NAME" &

# Check VM status
virsh dominfo "$VM_NAME"
```

### Method 2: Using virt-manager (GUI)

For graphical creation:

```bash
#!/bin/bash
set -euo pipefail

# Start virt-manager
virt-manager

# Then use GUI wizard:
# File > New Virtual Machine > Local Install Media > Select ISO > Configure resources
```

## Managing VMs with virsh

### Essential VM Operations

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"

# List all VMs (running and stopped)
virsh list --all

# Get detailed VM information
virsh dominfo "$VM_NAME"

# Start a VM
virsh start "$VM_NAME"

# Gracefully shutdown a VM
virsh shutdown "$VM_NAME"

# Force stop a VM (use if graceful fails)
virsh destroy "$VM_NAME"

# Reboot a VM
virsh reboot "$VM_NAME"

# Get VM memory and CPU usage
virsh domstats "$VM_NAME" --cpu --memory

# Connect to VM console
virsh console "$VM_NAME"
# Exit with Ctrl+]
```

### Snapshot Management

Snapshots capture VM state and allow rollback:

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"

# Create a snapshot before making changes
virsh snapshot-create-as "$VM_NAME" \
    --name "before-updates" \
    --description "Snapshot before system updates" \
    --atomic

# List snapshots
virsh snapshot-list "$VM_NAME"

# View snapshot details
virsh snapshot-info "$VM_NAME" --snapshotname "before-updates"

# Revert to a snapshot
virsh snapshot-revert "$VM_NAME" --snapshotname "before-updates"

# Delete a snapshot
virsh snapshot-delete "$VM_NAME" --snapshotname "before-updates"
```

### Cloning VMs

```bash
#!/bin/bash
set -euo pipefail

SOURCE_VM="ubuntu-server-01"
NEW_VM="ubuntu-server-02"

# Clone using virt-clone
sudo virt-clone \
    --original "$SOURCE_VM" \
    --name "$NEW_VM" \
    --file "/var/lib/libvirt/images/${NEW_VM}.qcow2"

# Start the cloned VM
virsh start "$NEW_VM"

# Verify clone
virsh list --all
```

## Disk Management and Storage

### Disk Format Comparison

**qcow2** (Quick Copy on Write):
- Supports snapshots and compression
- Thin provisioning (grows as needed)
- Slower than raw, but more flexible
- Recommended for most homelabs

**raw**:
- Better performance
- No snapshots or compression
- Fixed size allocation
- Use for performance-critical VMs

### Creating and Managing Disks

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}-data.qcow2"
DISK_SIZE=100  # GB

# Create a qcow2 disk
qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE}G"

# Check disk info
qemu-img info "$DISK_PATH"

# Resize a disk (expand only, cannot shrink)
qemu-img resize "$DISK_PATH" 150G

# Attach disk to running VM (requires XML editing)
# Or use virt-manager GUI: VM Details > Add Hardware > Storage

# List VM disks
virsh domblklist "$VM_NAME"

# Get disk block statistics
virsh domblkinfo "$VM_NAME" vda

# Backing up a VM disk
qemu-img convert -f qcow2 -O qcow2 \
    "$DISK_PATH" \
    "/backup/${VM_NAME}-backup.qcow2"
```

## Networking Configuration

### Network Modes

**NAT (Default virbr0)**:
- VMs get isolated network
- Access external via host
- Good for development

**Bridge**:
- VMs appear on host LAN
- Direct network access
- Better for services

### Creating a Bridge Network

```bash
#!/bin/bash
set -euo pipefail

# Create bridge configuration (netplan example for Debian/Ubuntu 20.04+)
cat <<'EOF' | sudo tee /etc/netplan/01-kvm-bridge.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
  bridges:
    br0:
      interfaces: [eth0]
      dhcp4: true
EOF

# Apply netplan changes
sudo netplan apply

# Verify bridge creation
ip link show | grep br0
brctl show
```

### Configuring VM Network

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"

# Edit VM network configuration
virsh edit "$VM_NAME"

# Change network line from:
# <interface type='network'> to <interface type='bridge'>
# And modify to use bridge:
# <source bridge='br0'/>

# Alternatively, add network interface to running VM
virsh attach-interface "$VM_NAME" --type bridge --source br0 --model virtio --live --persistent

# List VM network interfaces
virsh domiflist "$VM_NAME"

# Get network statistics
virsh domifstat "$VM_NAME" vnet0
```

## GPU Passthrough Basics

GPU passthrough requires significant system configuration. This overview covers the basics.

### Prerequisites

- Motherboard with IOMMU support (Intel VT-d or AMD-Vi)
- Dedicated GPU (don't passthrough your primary display GPU)
- Proper BIOS settings enabled
- Kernel parameters configured

### Enable IOMMU in BIOS

1. Reboot and enter BIOS
2. Find and enable:
   - **Intel**: VT-d (Intel Virtualization Technology for Directed I/O)
   - **AMD**: IOMMU (I/O Memory Management Unit)
3. Save and reboot

### Configure Kernel Parameters

```bash
#!/bin/bash
set -euo pipefail

# Edit GRUB config (Intel example)
GRUB_CMDLINE="intel_iommu=on iommu=pt"

# Or for AMD
GRUB_CMDLINE="amd_iommu=on iommu=pt"

# Add to /etc/default/grub
sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE} /" /etc/default/grub

# Update GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Reboot
sudo reboot
```

### Verify IOMMU Groups

```bash
#!/bin/bash
set -euo pipefail

# Check IOMMU groups
for g in /sys/kernel/iommu_groups/*/devices/*; do
    echo "$(basename $(dirname $g)): $(basename $g)"
done

# Identify your GPU device ID
lspci | grep -i gpu
```

### Bind GPU to vfio-pci

```bash
#!/bin/bash
set -euo pipefail

# Identify GPU PCI IDs (example: 01:00.0 and 01:00.1 for audio)
GPU_ID="01:00.0"
GPU_AUDIO="01:00.1"

# Add to vfio-pci (requires kernel modules configuration)
# This is complex and typically done via modprobe configuration or scripts
# Consult Arch Wiki for detailed setup specific to your hardware
```

## Performance Tuning

### CPU Pinning

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"

# Pin VM vCPUs to specific host CPUs
# Edit VM XML with virsh edit, modify <vcpu> section:
virsh edit "$VM_NAME"

# Add CPU pinning (example for 2 vCPUs on cores 2-3):
# <cputune>
#   <vcpupin vcpu='0' cpuset='2'/>
#   <vcpupin vcpu='1' cpuset='3'/>
# </cputune>

# Check VM CPU stats
virsh domstats "$VM_NAME" --vcpu
```

### Hugepages

Hugepages reduce memory overhead:

```bash
#!/bin/bash
set -euo pipefail

# Check huge page support
grep -i hugepage /proc/meminfo

# Allocate 1GB huge pages (example: 8 pages = 8GB)
echo 8 | sudo tee /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages

# Persist across reboots (add to /etc/sysctl.conf)
echo "vm.nr_hugepages=8" | sudo tee -a /etc/sysctl.conf

# In VM XML, add memory backing:
virsh edit "$VM_NAME"

# Add under <memory>:
# <memoryBacking>
#   <hugepages/>
# </memoryBacking>
```

### Virtio Drivers

Ensure VMs use virtio drivers for better performance:

```bash
#!/bin/bash
set -euo pipefail

# In VM XML, use:
# <interface type='network'>
#   <model type='virtio'/>
# </interface>

# For disks:
# <disk type='file'>
#   <driver type='qemu' name='qemu' cache='writeback' io='native'/>
#   <target bus='virtio'/>
# </disk>
```

## Live Migration

Live migration moves a running VM to another host without downtime. Requires shared storage (NFS/iSCSI).

```bash
#!/bin/bash
set -euo pipefail

SOURCE_HOST="kvm-host-1"
DEST_HOST="kvm-host-2"
VM_NAME="ubuntu-server-01"
SHARED_STORAGE="/mnt/shared/libvirt"

# List all VMs on source
virsh -c qemu+ssh://"${SOURCE_HOST}"/system list --all

# Perform live migration (from source host)
virsh -c qemu+ssh://"${SOURCE_HOST}"/system migrate \
    --live \
    --persistent \
    "$VM_NAME" \
    qemu+ssh://"${DEST_HOST}"/system

# Verify migration
virsh -c qemu+ssh://"${DEST_HOST}"/system list --all
```

## Troubleshooting

### VM Won't Start

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"

# Check VM configuration
virsh dominfo "$VM_NAME"

# Look for detailed errors
virsh start "$VM_NAME" 2>&1 | tee /tmp/vm_error.log

# Check libvirtd logs
sudo journalctl -u libvirtd -n 50 -e

# Validate VM XML
virsh define /tmp/vm.xml  # Will show syntax errors

# Check disk exists and is accessible
ls -lah /var/lib/libvirt/images/

# Verify sufficient disk space
df -h /var/lib/libvirt/images/
```

### High Memory Usage

```bash
#!/bin/bash
set -euo pipefail

# Check actual memory usage per VM
virsh domstats --memory

# Find memory hogs
virsh list --all | while read name id uuid; do
    if [[ "$id" != "Id" ]]; then
        virsh dominfo "$name" | grep "Used memory"
    fi
done
```

### Network Not Working in VM

```bash
#!/bin/bash
set -euo pipefail

VM_NAME="ubuntu-server-01"

# Check VM network configuration
virsh domiflist "$VM_NAME"

# Check bridge status on host
brctl show

# Restart network (inside VM)
sudo systemctl restart networking  # Debian/Ubuntu

# Check VM network XML
virsh dumpxml "$VM_NAME" | grep -A 5 "interface"

# Test network from host to VM
ping $(virsh domifaddr "$VM_NAME" --interface vnet0 | grep "ipv4" | awk '{print $4}' | cut -d/ -f1)
```

### Disk Performance Issues

```bash
#!/bin/bash
set -euo pipefault

VM_NAME="ubuntu-server-01"

# Check disk I/O stats
virsh domblkstat "$VM_NAME"

# Monitor real-time disk usage
virt-top

# Check for disk errors
sudo journalctl -u libvirtd | grep -i error
```

## Best Practices

1. **Use qcow2 for flexibility** - Snapshots and thin provisioning save space and time
2. **Implement resource limits** - Set max memory/CPU to prevent runaway VMs
3. **Regular snapshots** - Before major changes, take snapshots for easy rollback
4. **Backup disks externally** - Don't rely only on snapshots
5. **Use descriptive names** - `ubuntu-22-web-01` is better than `vm-1`
6. **Monitor performance** - Use `virt-top` to watch resource usage
7. **Keep images organized** - Store ISOs, disks, and backups in separate directories
8. **Document configurations** - Keep notes on purpose, resources, and network setup for each VM
9. **Use templates** - Create base VM templates for consistent deployments
10. **Security first** - Keep host and VMs updated; use strong passwords; isolate sensitive VMs

## Additional Resources

- [KVM Documentation](https://www.linux-kvm.org/page/Main_Page)
- [libvirt Documentation](https://libvirt.org/docs.html)
- [Arch Wiki KVM](https://wiki.archlinux.org/title/KVM)
- [Red Hat Virtualization Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/using-kvm_configuring-basic-system-settings)
- [Proxmox Documentation](https://pve.proxmox.com/wiki/Main_Page) (KVM-based hypervisor)
- [QEMU Documentation](https://qemu.readthedocs.io/)

---

✅ **You now have a complete KVM/QEMU virtualization setup with practical commands for VM creation, management, advanced features, and troubleshooting!**
