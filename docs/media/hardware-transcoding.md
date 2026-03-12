# 🎛️ GPU Passthrough and Hardware Transcoding #media #gpu #transcoding #hardware #passthrough

Offload video encoding/decoding to GPU hardware, reducing CPU usage dramatically. Learn GPU passthrough in Proxmox/KVM, Docker GPU access, and verification methods.

## Table of Contents
1. [Why Hardware Transcoding](#why-hardware-transcoding)
2. [Supported Hardware](#supported-hardware)
3. [GPU Passthrough in Proxmox](#gpu-passthrough-in-proxmox)
4. [GPU Passthrough in KVM](#gpu-passthrough-in-kvm)
5. [Docker GPU Access](#docker-gpu-access)
6. [Intel Quick Sync Setup](#intel-quick-sync-setup)
7. [NVIDIA GPU Setup](#nvidia-gpu-setup)
8. [Verifying Transcoding](#verifying-transcoding)
9. [Performance Comparison](#performance-comparison)
10. [Troubleshooting](#troubleshooting)
11. [Additional Resources](#additional-resources)

## Why Hardware Transcoding

**CPU-only transcoding:**
- Uses 30-60% of CPU per stream
- Generates significant heat
- Throttles system performance
- Expensive power consumption

**GPU transcoding:**
- Uses 5-15% of CPU per stream
- Minimal heat generation
- Non-blocking (CPU free for other tasks)
- Lower power consumption (TDP ~25-45W)

**ROI Example:**
- Server CPU: 8 cores, 95W TDP
- GPU: 25W TDP
- Total power saving: 70W+ when transcoding
- Cost: $100-300 GPU investment

## Supported Hardware

### Intel Quick Sync (QSV)

Supported CPUs:
- 2nd Gen Core and newer (i3/i5/i7)
- Atom J1900+
- Celeron N3050+
- Pentium N3700+

Benefits:
- Built-in (no separate purchase)
- Low power consumption
- Good support in FFmpeg
- Available in most consumer CPUs

### NVIDIA NVENC

Supported GPUs:
- GTX 900 series and newer (Maxwell arch+)
- RTX series (Turing, Ampere)
- Quadro RTX series

Benefits:
- Excellent documentation
- Supports H.264, HEVC, VP9
- Best performance overall
- Widely available

Popular options:
- RTX 3050 Ti (~$200, entry-level)
- RTX 3060 Ti (~$300, excellent value)
- RTX 4060 (~$200, latest)

### AMD VCE/VCN

Supported GPUs:
- Radeon RX 470/480 and newer
- Radeon RX 5700 XT
- Radeon RX 6700 XT+

Benefits:
- Similar performance to NVIDIA
- More affordable historically

### Apple Silicon

M1/M2/M3 chips:
- Built-in hardware transcoding
- Excellent efficiency
- Limited server GPU options

## GPU Passthrough in Proxmox

GPU passthrough allows VM full access to GPU hardware.

### Prerequisites

Enable IOMMU in BIOS:
- Intel: VT-d (Virtualization Technology for Directed I/O)
- AMD: AMD-V with IOMMU

### Step 1: Enable IOMMU

Edit `/etc/default/grub`:

```bash
# Intel systems
GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt pcie_acs_override=downstream vfio_iommu_type1.allow_unsafe_interrupts=1"

# AMD systems
GRUB_CMDLINE_LINUX_DEFAULT="amd_iommu=on iommu=pt pcie_acs_override=downstream vfio_iommu_type1.allow_unsafe_interrupts=1"
```

Apply changes:

```bash
update-grub
reboot
```

### Step 2: Identify GPU

```bash
lspci | grep -i vga
# Output: 01:00.0 VGA compatible controller: NVIDIA Corporation GP104 [GeForce GTX 1080]

# Full details
lspci -nnv | grep -A 20 "NVIDIA"
# Look for: 01:00.0 and 01:00.1
```

### Step 3: Isolate GPU

Edit `/etc/modprobe.d/vfio.conf`:

```bash
options vfio-pci ids=10de:1b80,10de:10f0
# Use your device IDs from lspci -nn
```

Blacklist GPU drivers:

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
```

Rebuild initramfs:

```bash
update-initramfs -u -k all
reboot
```

### Step 4: Verify IOMMU Groups

```bash
#!/bin/bash
shopt -s nullglob
for d in /sys/kernel/iommu_groups/*/devices/*; do
    n=${d%/*}
    n=${n##*/}
    echo "IOMMU Group $n:"
    lspci -nns "${d##*/}"
done

# Ideal: GPU in isolated group
# IOMMU Group 12:
# 01:00.0 VGA compatible controller
# 01:00.1 Audio device
```

### Step 5: Add GPU to VM

In Proxmox UI:
1. VM → Hardware → Add PCI Device
2. Select GPU from dropdown
3. Check "All Functions" (includes audio)
4. Check "ROM Bar" (optional, some GPUs need this)

Or via CLI:

```bash
qm set 100 -hostpci0 01:00,pcie=1,x-vga=1
# VM ID: 100
# GPU address: 01:00
# x-vga=1: primary display
```

## GPU Passthrough in KVM

### Enable IOMMU (same as Proxmox)

### Define GPU Group

```bash
#!/bin/bash
# Find IOMMU group for GPU
lspci -nnv | grep -i nvidia
# 01:00.0 [10de:1b80]
# 01:00.1 [10de:10f0]
```

### Libvirt Configuration

Edit VM XML:

```xml
<domain type='kvm'>
  <name>media-server</name>
  <hostdev mode='subsystem' type='pci' managed='yes'>
    <source>
      <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </source>
  </hostdev>
  <hostdev mode='subsystem' type='pci' managed='yes'>
    <source>
      <address domain='0x0000' bus='0x01' slot='0x00' function='0x1'/>
    </source>
  </hostdev>
</domain>
```

Apply configuration:

```bash
virsh define /tmp/vm.xml
virsh start media-server
```

## Docker GPU Access

### Intel GPU Access

Device flag method:

```bash
docker run --device /dev/dri/renderD128:/dev/dri/renderD128 \
  --device /dev/dri/card0:/dev/dri/card0 \
  jellyfin:latest
```

Docker Compose:

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    devices:
      - /dev/dri/renderD128:/dev/dri/renderD128
      - /dev/dri/card0:/dev/dri/card0
    volumes:
      - /opt/jellyfin/config:/config
      - /mnt/media:/media:ro
```

### NVIDIA GPU Access

Install nvidia-docker2:

```bash
# Setup repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install
sudo apt-get update && sudo apt-get install -y nvidia-docker2

# Restart Docker daemon
sudo systemctl restart docker
```

Docker Compose with NVIDIA:

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video_decode,video_encode
    volumes:
      - /opt/jellyfin/config:/config
      - /mnt/media:/media:ro
```

## Intel Quick Sync Setup

### Prerequisites

Check for QSV support:

```bash
# Check CPU supports Quick Sync
lscpu | grep -i quick
# or
grep -i quick /proc/cpuinfo

# List Intel GPUs
lspci | grep -i intel | grep -i vga
```

### Docker Setup

In Plex docker-compose.yml:

```yaml
plex:
  image: plexinc/pms-docker:latest
  devices:
    - /dev/dri/renderD128:/dev/dri/renderD128
    - /dev/dri/card0:/dev/dri/card0
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
```

### Jellyfin QSV Configuration

```bash
# Verify permissions
ls -la /dev/dri/
# renderD128 should be readable by docker user

# Fix if needed
sudo usermod -aG video 1000  # 1000 = docker user UID
sudo usermod -aG render 1000
```

Jellyfin settings:
```
Settings → Playback → Transcoding
Hardware Acceleration: Intel Quick Sync
```

### Testing QSV

```bash
# Start transcode and monitor
watch -n 1 'ps aux | grep ffmpeg'

# Check GPU usage
sudo intel_gpu_top
# Should show Video Encode/Decode activity
```

## NVIDIA GPU Setup

### Driver Installation

```bash
# Install NVIDIA driver
sudo apt-get update
sudo apt-get install -y nvidia-driver-535
# Version varies; check nvidia.com for latest

# Verify installation
nvidia-smi
```

### nvidia-container-toolkit

Install via system package manager:

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### Docker Configuration

Default runtime (optional):

```bash
# Edit /etc/docker/daemon.json
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}

# Restart Docker
sudo systemctl restart docker
```

### Testing NVIDIA

```bash
# Test nvidia-docker
docker run --rm --runtime=nvidia nvidia/cuda:11.8.0-runtime-ubuntu22.04 nvidia-smi

# Should output GPU information
```

## Verifying Transcoding

### Monitor Active Transcodes

**Plex:**

```bash
# Get sessions with transcoding
curl -s http://localhost:32400/status/sessions \
  -H "X-Plex-Token: YOUR_TOKEN" | \
  python3 -m json.tool | grep -i transcode
```

**Jellyfin:**

```bash
# Check logs for transcoding
docker-compose logs -f jellyfin | grep -i transcode
```

### Check GPU Utilization

**Intel QSV:**

```bash
# Install intel-gpu-tools
sudo apt-get install -y intel-gpu-tools

# Monitor real-time
sudo intel_gpu_top

# Should show Video Encode/Decode activity
```

**NVIDIA:**

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Detailed encoding
nvidia-smi pmon -c 10
# Should show ENC column with activity
```

### FFmpeg Verification

```bash
# Test encode with QSV
ffmpeg -hwaccel qsv -c:v h264_qsv -i input.mp4 \
  -c:v h264_qsv -crf 23 output.mp4

# Test encode with NVIDIA
ffmpeg -c:v h264_cuvid -i input.mp4 \
  -c:v h264_nvenc -preset fast output.mp4
```

## Performance Comparison

### Benchmarks

| Scenario | CPU Only | Intel QSV | NVIDIA NVENC |
|----------|----------|-----------|--------------|
| H.264 1080p60 encode | 35% CPU | 8% CPU + GPU | 5% CPU + GPU |
| HEVC 4K30 encode | 85% CPU | 12% CPU + GPU | 8% CPU + GPU |
| Power draw (encoding) | 95W | 45W | 50W |
| Startup time | ~2sec | ~1sec | ~1sec |
| Quality (CRF 23) | Excellent | Good | Good |

### Cost-Benefit

8-stream transcoding setup:
- CPU-only: 280% CPU (impossible), 760W power
- GPU-assisted: 64% CPU, 400W power
- Savings: 216% CPU, 360W power

ROI: GPU pays for itself in 1 year via electricity savings.

## Troubleshooting

### GPU not detected in Plex/Jellyfin

```bash
# Check device permissions
docker-compose exec plex ls -la /dev/dri/

# Fix ownership
docker-compose exec plex chown 1000:1000 /dev/dri/renderD128

# Restart service
docker-compose restart plex
```

### Transcoding still using CPU

```bash
# Verify hardware acceleration enabled in settings
# Check logs for codec mismatches
docker-compose logs plex | grep -i transcode

# Some formats don't support hardware encoding
# (e.g., VP9 has limited NVIDIA support)
```

### Performance worse than CPU

```bash
# May indicate wrong format or settings
# Verify container has GPU access
docker-compose exec plex nvidia-smi

# Check transcode settings use correct codec
```

### Driver issues after update

```bash
# Reinstall drivers
sudo apt-get update
sudo apt-get install --reinstall -y nvidia-driver-535

# Restart Docker daemon
sudo systemctl restart docker
```

## Best Practices

1. **Match encoding codec** to available acceleration
2. **Monitor GPU temp** (should stay under 80C)
3. **Set transcode bitrate limits** to prevent CPU spike
4. **Test with actual files** before production
5. **Keep drivers updated** monthly
6. **Backup GPU config** before major updates
7. **Use quality profiles** that match capability

## Additional Resources

- [Intel Quick Sync FFmpeg Wiki](https://trac.ffmpeg.org/wiki/Encode/H.264)
- [NVIDIA NVENC Developer Guide](https://developer.nvidia.com/video-encode)
- [Plex Transcoding Documentation](https://support.plex.tv/articles/200375666-transcoding/)
- [Jellyfin Hardware Acceleration](https://docs.jellyfin.org/general/administration/hardware-acceleration/)
- [Proxmox PCI Passthrough](https://pve.proxmox.com/wiki/Pci_passthrough)

---

✅ **GPU hardware transcoding configured—video encoding now offloaded to dedicated silicon!**
