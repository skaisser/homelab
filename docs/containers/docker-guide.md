# 🐳 Docker Commands #docker #containers #virtualization

> A comprehensive guide for Docker commands and best practices for container management.

## 📋 Table of Contents
- [Container Inspection](#-inspecting-container-ip-and-mac-address)
- [Network Management](#-listing-networks-and-creating-macvlan)
- [Container Management](#-running-containers-with-port-mappings)
- [Logging and Monitoring](#-useful-container-inspection-and-logging-commands)
- [Volume Management](#-creating-and-managing-volumes)
- [Resource Management](#️-managing-container-resources-memory-cpu)
- [Debugging](#-debugging-containers)
- [Docker Compose](#-common-docker-compose-tips)

## 🔍 Inspecting Container IP and MAC Address

### Get Docker Running IP Address
```bash
# Get container IP address
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' docker-instance-name

# Get all network details
docker inspect -f '{{json .NetworkSettings.Networks}}' docker-instance-name | jq
```
> 💡 **Tip**: Use `jq` for better JSON formatting

### Get Docker Running MAC Address
```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}}' docker-instance-name
```

## 🌐 Listing Networks and Creating Macvlan

### Show Docker Networks
```bash
# List all networks
docker network ls

# Inspect specific network
docker network inspect network-name
```

### Create Docker Network using br0 with Macvlan
```bash
# Create a macvlan network
docker network create --driver=macvlan \
    --subnet=10.0.0.0/23 \
    --gateway=10.0.0.1 \
    -o parent=br0 br0
```
> ⚠️ **Note**: Ensure your host network interface supports promiscuous mode

## 🚀 Running Containers with Port Mappings

### Run a Container with Port Mapping
```bash
# Basic port mapping
docker run -d --rm -p host-port:container-port --name=container-name image-name

# Multiple port mappings
docker run -d \
    -p 80:80 \
    -p 443:443 \
    --name=nginx \
    nginx:latest
```

## 📜 Useful Container Inspection and Logging Commands

### Get Docker Logs
```bash
# Get recent logs
docker logs container-name

# Follow logs in real-time
docker logs -f container-name

# Show timestamps
docker logs -t container-name

# Show last N lines
docker logs --tail=100 container-name
```

### Inspect Running Container
```bash
# Full container inspection
docker inspect container-name

# Get specific information
docker inspect -f '{{ .State.Status }}' container-name
docker inspect -f '{{ .Config.Env }}' container-name
```

## 📦 Creating and Managing Volumes

### Volume Management
```bash
# Create a named volume
docker volume create volume-name

# List all volumes
docker volume ls

# Inspect volume
docker volume inspect volume-name

# Remove unused volumes
docker volume prune
```

## 🛠️ Mounting Bind Volumes

### Bind Mounts and Volumes
```bash
# Bind mount (host directory)
docker run -v /host/path:/container/path:ro --name=container-name image-name

# Named volume
docker run -v volume-name:/container/path --name=container-name image-name

# Temporary mount (tmpfs)
docker run --tmpfs /container/path --name=container-name image-name
```
> 💡 **Tip**: Use `:ro` for read-only mounts

## ⚙️ Managing Container Resources (Memory, CPU)

### Resource Limits
```bash
# Memory limits
docker run -m 512m --memory-reservation=256m --name=container-name image-name

# CPU limits
docker run \
    --cpus=".5" \
    --cpu-shares=512 \
    --name=container-name image-name
```
> 📊 **Monitor**: Use `docker stats` to check resource usage

## 🐞 Debugging Containers

### Container Debugging
```bash
# Interactive shell
docker exec -it container-name /bin/bash

# Run specific command
docker exec container-name command

# Copy files from/to container
docker cp container-name:/path/to/file ./local/path
```

## 📝 Common Docker Compose Tips

### Docker Compose Commands
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Scale services
docker-compose up -d --scale service=3

# Rebuild containers
docker-compose up -d --build
```

> 🔄 **Best Practice**: Always use version control for your `docker-compose.yml` files

---

💡 **Quick Tips**:
- Use `docker system prune` to clean up unused resources
- Implement health checks in your containers
- Use `.dockerignore` to exclude unnecessary files
- Tag your images properly for version control
- Always use specific image versions in production
