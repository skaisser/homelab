# 🐋 Docker Compose Guide #docker #containers #compose #devops

A comprehensive guide to using Docker Compose for managing multi-container applications.

## 📋 Table of Contents
- [What is Docker Compose?](#what-is-docker-compose)
- [Basic Concepts](#basic-concepts)
- [File Structure](#file-structure)
- [Common Commands](#common-commands)
- [Example Configurations](#example-configurations)
- [Management Tools](#management-tools)
- [Best Practices](#best-practices)

## 🤔 What is Docker Compose?

Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services, networks, and volumes.

## 📚 Basic Concepts

### Services
Services are the containers that make up your application. Each service runs a single container and is defined in the docker-compose.yml file.

### Networks
Networks enable communication between containers. By default, Compose creates a network for your application.

### Volumes
Volumes are used for persistent data storage and sharing data between containers and the host system.

## 📁 File Structure

Basic structure of a `docker-compose.yml` file:
```yaml
services:
  service_name:
    image: image_name
    container_name: container_name
    environment:
      - KEY=value
    ports:
      - "host_port:container_port"
    volumes:
      - /host/path:/container/path
    networks:
      - network_name
    restart: unless-stopped

networks:
  network_name:
    driver: bridge

volumes:
  volume_name:
```

## 🛠 Common Commands

### Basic Operations
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service_name]

# List services
docker-compose ps

# Restart services
docker-compose restart [service_name]

# Pull latest images
docker-compose pull

# Build/rebuild services
docker-compose build
```

## 📝 Example Configurations

> **Security Notice**: The examples below use placeholder credentials for demonstration only. In production, never hardcode passwords in compose files — use `.env` files or Docker secrets instead.

### 1. WordPress with MySQL
```yaml
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=secret
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=somewordpress
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=secret
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  wordpress_data:
  db_data:
```

### 2. NGINX with Let's Encrypt
```yaml
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/letsencrypt
    restart: unless-stopped

  certbot:
    image: certbot/certbot
    volumes:
      - ./certs:/etc/letsencrypt
    command: certonly --webroot -w /var/www/certbot
```

### 3. Monitoring Stack
```yaml
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: unless-stopped

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  grafana_data:
```

## 🎯 Management Tools

### Portainer
Portainer is a powerful Docker management UI that makes it easy to manage your Docker environments.

```yaml
services:
  portainer:
    image: portainer/portainer-ce
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped

volumes:
  portainer_data:
```

### Dockge
Dockge is a modern, lightweight Docker Compose stack manager with a clean web UI.

```yaml
services:
  dockge:
    image: louislam/dockge:1
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      - /opt/stacks:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks

volumes:
  dockge_data:
```

## 💡 Best Practices

1. **Version Control**
   - Keep your docker-compose files in version control
   - Use `.env` files for environment variables
   - Document your configurations

2. **Security**
   - Never commit sensitive data to version control
   - Use secrets management for sensitive data
   - Regularly update your images

3. **Resource Management**
   - Set resource limits for containers
   - Use health checks
   - Implement proper logging

4. **Network Security**
   - Only expose necessary ports
   - Use internal networks when possible
   - Implement proper access controls

5. **Data Management**
   - Use named volumes for persistence
   - Implement regular backups
   - Plan for data migration

## 🔧 Troubleshooting Tips

1. **Check Logs**
```bash
# View service logs
docker-compose logs -f service_name

# View container logs
docker logs container_name
```

2. **Check Container Status**
```bash
# List containers
docker-compose ps

# Show container details
docker inspect container_name
```

3. **Network Issues**
```bash
# List networks
docker network ls

# Inspect network
docker network inspect network_name
```

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Dockge GitHub](https://github.com/louislam/dockge)

> 💡 **Pro Tip**: Start with Portainer or Dockge for easier container management, especially if you're new to Docker Compose. These tools provide user-friendly interfaces for managing your containers and viewing logs.
