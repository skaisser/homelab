# ☸️ K3s/K8s for Homelab #kubernetes #k3s #k8s #containers #orchestration

Kubernetes (K8s) powers production environments worldwide, but it's traditionally resource-heavy. K3s—a lightweight Kubernetes distribution—makes container orchestration accessible for homelabs, providing enterprise features in just 40MB. This guide covers K3s installation, application deployment, networking, storage, and monitoring, with practical examples for homelab workloads.

## Table of Contents

- [Why Kubernetes in a Homelab](#why-kubernetes-in-a-homelab)
- [K3s vs Full Kubernetes](#k3s-vs-full-kubernetes)
- [Single-Node K3s Installation](#single-node-k3s-installation)
- [Multi-Node Cluster Setup](#multi-node-cluster-setup)
- [kubectl Basics](#kubectl-basics)
- [Deploying Applications with Manifests](#deploying-applications-with-manifests)
- [Helm Package Manager](#helm-package-manager)
- [Services and Ingress](#services-and-ingress)
- [Persistent Storage](#persistent-storage)
- [Namespaces and RBAC](#namespaces-and-rbac)
- [Secrets Management](#secrets-management)
- [Monitoring with Lens and k9s](#monitoring-with-lens-and-k9s)
- [Common Homelab Deployments](#common-homelab-deployments)
- [Upgrading K3s](#upgrading-k3s)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## Why Kubernetes in a Homelab

**Benefits**:
- Learn enterprise container orchestration
- High availability and self-healing
- Easy service discovery and load balancing
- Rolling updates without downtime
- Standardized deployment approach

**When to use K3s**:
- Running multiple containerized services
- Want automatic restarts and scaling
- Learning Kubernetes for production
- Have 2+ GB RAM available

**When NOT to use K3s** (use Docker instead):
- Single simple service
- Very resource-constrained (< 1GB)
- Just learning containers basics

## K3s vs Full Kubernetes

| Feature | K3s | Full K8s |
|---------|-----|----------|
| **Size** | 40MB | 1GB+ |
| **Memory** | 512MB min | 2GB+ |
| **Install** | One command | Complex |
| **Features** | Most K8s features | All features |
| **Production** | Yes, enterprise-ready | Yes, standard |
| **Homelab** | Perfect | Overkill |

**Recommendation**: Use K3s for homelab, full K8s only if needed for specific cloud provider features.

## Single-Node K3s Installation

### Prerequisites

```bash
#!/bin/bash
set -euo pipefail

# Check system requirements
echo "=== System Check ==="
grep -c processor /proc/cpuinfo || echo "CPU check"
free -h | grep Mem

# Minimum requirements
# - 512MB RAM (1GB+ recommended)
# - 1 CPU core (2+ recommended)
# - 10GB disk space
# - Linux (Ubuntu, Debian, Fedora, etc.)

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y curl wget cgroup-tools
```

### Quick Installation

```bash
#!/bin/bash
set -euo pipefail

# Single command installation (curl script)
curl -sfL https://get.k3s.io | sh -

# Verify installation
sudo k3s kubectl get nodes
sudo k3s kubectl get pods --all-namespaces

# Wait for all system pods to be ready
echo "Waiting for K3s to fully initialize..."
sleep 10
sudo k3s kubectl wait --for=condition=ready node --all --timeout=300s
```

### K3s Configuration

```bash
#!/bin/bash
set -euo pipefail

# K3s installs to /etc/rancher/k3s/
# Configuration file: /etc/rancher/k3s/k3s.yaml

# View kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml

# Copy kubeconfig for non-root user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER":"$USER" ~/.kube/config

# Verify kubectl works without sudo
kubectl get nodes
```

### Enable shell completion

```bash
#!/bin/bash
set -euo pipefail

# For bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc

# For zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc

# Apply immediately
source ~/.bashrc
```

## Multi-Node Cluster Setup

### Server Node Setup

```bash
#!/bin/bash
set -euo pipefail

# Export token (save this for adding nodes)
export K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
export SERVER_IP="192.168.1.100"  # Server node IP

echo "Server token (save for agent nodes): $K3S_TOKEN"
echo "Server IP: $SERVER_IP"

# Start K3s server (already running, but shown for reference)
# sudo k3s server --token=$K3S_TOKEN
```

### Agent Node Setup

```bash
#!/bin/bash
set -euo pipefail

# On agent/worker nodes
K3S_TOKEN="${K3S_TOKEN:-}"  # Set from server node
K3S_URL="https://192.168.1.100:6443"  # Server IP:port

if [[ -z "$K3S_TOKEN" ]]; then
    echo "ERROR: K3S_TOKEN not set. Get from server node:"
    echo "sudo cat /var/lib/rancher/k3s/server/node-token"
    exit 1
fi

# Install K3s agent
curl -sfL https://get.k3s.io | K3S_URL="$K3S_URL" K3S_TOKEN="$K3S_TOKEN" sh -

# Verify on server
kubectl get nodes
```

### Verify Multi-Node Cluster

```bash
#!/bin/bash
set -euo pipefail

# Check all nodes
kubectl get nodes -o wide

# Check node status
kubectl describe node <node-name>

# Verify workloads can schedule across nodes
kubectl get pods --all-namespaces -o wide
```

## kubectl Basics

### Essential Commands

```bash
#!/bin/bash
set -euo pipefail

# Cluster info
kubectl cluster-info
kubectl version --short

# Node management
kubectl get nodes
kubectl describe node <node-name>
kubectl cordon <node-name>    # Prevent new pods
kubectl uncordon <node-name>
kubectl drain <node-name>     # Gracefully remove pods

# Pod management
kubectl get pods --all-namespaces
kubectl get pods -o wide     # Show node assignment
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -f   # Follow logs
kubectl exec -it <pod-name> -- bash   # Shell into pod

# Resource viewing
kubectl get all -n <namespace>
kubectl get pvc                # Persistent Volume Claims
kubectl get svc                # Services
kubectl top nodes              # Node resource usage
kubectl top pods               # Pod resource usage

# Common editing
kubectl edit deployment <name> -n <namespace>
kubectl set image deployment/<name> <container>=<image>:<tag>
kubectl scale deployment <name> --replicas=3
```

### Context and Namespace Management

```bash
#!/bin/bash
set -euo pipefail

# View current context
kubectl config current-context

# List available contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Create namespace
kubectl create namespace homelab

# Set default namespace
kubectl config set-context --current --namespace=homelab

# View all resources in namespace
kubectl get all -n homelab
```

## Deploying Applications with Manifests

### Simple Deployment Example (Nginx)

```yaml
# Save as nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-web
  namespace: homelab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-web
  template:
    metadata:
      labels:
        app: nginx-web
    spec:
      containers:
      - name: nginx
        image: nginx:1.24-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
```

### Deploy the Application

```bash
#!/bin/bash
set -euo pipefail

# Create namespace
kubectl create namespace homelab 2>/dev/null || true

# Deploy
kubectl apply -f nginx-deployment.yaml

# Monitor deployment
kubectl rollout status deployment/nginx-web -n homelab

# Check pods
kubectl get pods -n homelab

# View logs
kubectl logs deployment/nginx-web -n homelab
```

### ConfigMap and Secrets Example

```yaml
# configmap.yaml - Store configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: homelab
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  DB_HOST: "postgres.homelab.svc.cluster.local"
---
# secret.yaml - Store sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: homelab
type: Opaque
stringData:
  DB_USER: "dbuser"
  DB_PASSWORD: "${DB_PASSWORD}"  # Set via environment variable
  API_KEY: "${API_KEY}"
```

### Deploy with Environment Variables

```bash
#!/bin/bash
set -euo pipefail

# Set sensitive values from environment
export DB_PASSWORD="secure-password-123"
export API_KEY="secret-api-key"

# Create secrets from literals
kubectl create secret generic app-secrets \
    --from-literal=DB_USER=dbuser \
    --from-literal=DB_PASSWORD="$DB_PASSWORD" \
    --from-literal=API_KEY="$API_KEY" \
    -n homelab

# Reference in pod
# env:
# - name: DB_PASSWORD
#   valueFrom:
#     secretKeyRef:
#       name: app-secrets
#       key: DB_PASSWORD
```

## Helm Package Manager

### Install Helm

```bash
#!/bin/bash
set -euo pipefail

# Download and install
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version

# Add common repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### Deploy with Helm

```bash
#!/bin/bash
set -euo pipefail

# Search for charts
helm search repo nginx

# Install a chart
helm install my-nginx bitnami/nginx \
    --namespace homelab \
    --create-namespace \
    --set service.type=LoadBalancer

# List installed releases
helm list -n homelab

# Upgrade a release
helm upgrade my-nginx bitnami/nginx \
    --namespace homelab \
    --set replicaCount=3

# Check release status
helm status my-nginx -n homelab

# View release values
helm get values my-nginx -n homelab

# Uninstall
helm uninstall my-nginx -n homelab
```

### Popular Homelab Helm Charts

```bash
#!/bin/bash
set -euo pipefail

# Ingress Controller (Traefik - default in K3s)
helm repo add traefik https://helm.traefik.io
helm install traefik traefik/traefik -n kube-system

# Cert Manager (SSL/TLS)
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true

# Database: PostgreSQL
helm install postgres bitnami/postgresql \
    --namespace homelab \
    --create-namespace \
    --set auth.password=secure-pass

# Monitoring: Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace
```

## Services and Ingress

### Expose Application with Service

```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: homelab
spec:
  type: ClusterIP  # ClusterIP, NodePort, or LoadBalancer
  ports:
  - port: 80       # Service port
    targetPort: 80 # Pod port
    protocol: TCP
  selector:
    app: nginx-web
```

### Ingress Configuration (URL-based routing)

```yaml
# nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: homelab
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - web.example.com
    secretName: web-tls
  rules:
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

### Deploy Services

```bash
#!/bin/bash
set -euo pipefail

# Deploy service
kubectl apply -f nginx-service.yaml

# Verify service
kubectl get svc -n homelab
kubectl describe svc nginx-service -n homelab

# Access via port-forward
kubectl port-forward svc/nginx-service 8080:80 -n homelab

# Then visit: http://localhost:8080
```

## Persistent Storage

### Storage Classes and PVCs

```yaml
# persistent-storage.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: homelab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-path  # K3s default
---
# Pod using the storage
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
  namespace: homelab
spec:
  containers:
  - name: app
    image: app:latest
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: app-data
```

### Deploy Storage

```bash
#!/bin/bash
set -euo pipefail

# Check available storage classes
kubectl get storageclass

# Create PVC
kubectl apply -f persistent-storage.yaml

# Check PVC status
kubectl get pvc -n homelab

# View PVC details
kubectl describe pvc app-data -n homelab

# Check where data is stored (on K3s)
sudo ls -la /var/lib/rancher/k3s/storage/
```

## Namespaces and RBAC

### Create and Manage Namespaces

```bash
#!/bin/bash
set -euo pipefail

# Create namespaces for organization
kubectl create namespace homelab
kubectl create namespace monitoring
kubectl create namespace ingress-nginx

# Label namespaces
kubectl label namespace homelab environment=prod
kubectl label namespace monitoring environment=prod

# View namespaces
kubectl get namespaces

# Set default namespace for session
kubectl config set-context --current --namespace=homelab
```

### Role-Based Access Control (RBAC)

```yaml
# rbac-example.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: homelab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-reader
  namespace: homelab
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-read
  namespace: homelab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-reader
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: homelab
```

## Secrets Management

### Create Secrets from Files

```bash
#!/bin/bash
set -euo pipefail

# Create secret from file
echo "super-secret-value" > /tmp/secret.txt
kubectl create secret generic file-secret \
    --from-file=/tmp/secret.txt \
    -n homelab

# Create secret from multiple files
kubectl create secret generic config-secret \
    --from-file=config.yaml=./config.yaml \
    --from-file=key.pem=./key.pem \
    -n homelab

# View secret (base64 encoded)
kubectl get secret file-secret -n homelab -o yaml

# Decode secret
kubectl get secret file-secret -n homelab \
    -o jsonpath='{.data.secret\.txt}' | base64 -d
```

### TLS/SSL Secrets

```bash
#!/bin/bash
set -euo pipefail

# Create TLS secret from certificate files
kubectl create secret tls web-tls \
    --cert=./cert.pem \
    --key=./key.pem \
    -n homelab

# Use in Ingress
# tls:
# - hosts:
#   - example.com
#   secretName: web-tls
```

## Monitoring with Lens and k9s

### Install Lens (Kubernetes IDE)

```bash
#!/bin/bash
set -euo pipefail

# Download from https://k8slens.dev/
# Or via package manager (example for Linux)
wget https://distributions.lens.app/stable/Lens-5.7.2.AppImage
chmod +x Lens-5.7.2.AppImage
./Lens-5.7.2.AppImage

# Then add your K3s cluster using kubeconfig
```

### Install k9s (Terminal UI)

```bash
#!/bin/bash
set -euo pipefail

# Install k9s
curl -sS https://webinstall.dev/k9s | bash

# Or via package manager
sudo apt-get install k9s

# Launch k9s
k9s

# Navigation tips:
# `:pods` - show pods
# `:svc` - show services
# `:logs` - show logs
# `:help` - show help
# `q` - quit
```

## Common Homelab Deployments

### Pi-hole (DNS/Ad Blocker)

```bash
#!/bin/bash
set -euo pipefail

# Add Helm repo
helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/
helm repo update

# Install Pi-hole
helm install pihole mojo2600/pihole \
    --namespace homelab \
    --create-namespace \
    --set serviceWeb.loadBalancerIP=192.168.1.50 \
    --set persistentVolumeClaim.enabled=true

# Get admin password
kubectl get secret pihole -n homelab \
    -o jsonpath='{.data.WEBPASSWORD}' | base64 -d
```

### Home Assistant

```bash
#!/bin/bash
set -euo pipefail

# Add Helm repo
helm repo add k8s-at-home https://k8s-at-home.com/charts/

# Install Home Assistant
helm install home-assistant k8s-at-home/home-assistant \
    --namespace homelab \
    --set persistence.config.enabled=true \
    --set persistence.config.size=10Gi
```

### PostgreSQL Database

```bash
#!/bin/bash
set -euo pipefail

# Install PostgreSQL
helm install postgres bitnami/postgresql \
    --namespace homelab \
    --set auth.postgresPassword=secure-password \
    --set auth.database=homelab \
    --set persistence.enabled=true \
    --set persistence.size=20Gi

# Connect from host
kubectl port-forward svc/postgres 5432:5432 -n homelab

# Then connect: psql -h localhost -U postgres
```

### Nextcloud (File Sync)

```bash
#!/bin/bash
set -euo pipefail

helm repo add nextcloud https://nextcloud.github.io/helm/
helm install nextcloud nextcloud/nextcloud \
    --namespace homelab \
    --set nextcloud.password=admin123 \
    --set mariadb.enabled=true \
    --set persistence.enabled=true
```

## Upgrading K3s

### Single-Node Upgrade

```bash
#!/bin/bash
set -euo pipefail

# Check current version
k3s --version

# Upgrade (uses release channel)
curl -sfL https://get.k3s.io | sh -

# Or upgrade to specific version
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.0 sh -

# Verify upgrade
k3s --version
kubectl get nodes
```

### Multi-Node Upgrade

```bash
#!/bin/bash
set -euo pipefault

# 1. Upgrade server node first
# SSH to server and run upgrade script above

# 2. Wait for server to be ready
kubectl wait --for=condition=ready node/<server-name> --timeout=300s

# 3. Upgrade each agent node
# SSH to each agent and run:
curl -sfL https://get.k3s.io | K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> sh -

# 4. Verify all nodes
kubectl get nodes
```

## Troubleshooting

### Pod Not Running

```bash
#!/bin/bash
set -euo pipefail

POD_NAME="app-pod"
NAMESPACE="homelab"

# Get pod status
kubectl describe pod "$POD_NAME" -n "$NAMESPACE"

# View pod logs
kubectl logs "$POD_NAME" -n "$NAMESPACE"

# View previous container logs (if crashed)
kubectl logs "$POD_NAME" -n "$NAMESPACE" --previous

# Check events
kubectl get events -n "$NAMESPACE" | grep "$POD_NAME"

# Debug with temporary pod
kubectl run -it --image=alpine debug --restart=Never -n "$NAMESPACE" -- sh
```

### Service Not Accessible

```bash
#!/bin/bash
set -euo pipefault

SERVICE_NAME="nginx-service"
NAMESPACE="homelab"

# Check service
kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE"

# Check endpoints
kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE"

# Test DNS resolution from pod
kubectl run -it --image=alpine dnstest --restart=Never -n "$NAMESPACE" -- \
    nslookup "$SERVICE_NAME"

# Check if pods are actually running
kubectl get pods -n "$NAMESPACE" -l app=nginx-web
```

### Persistent Volume Issues

```bash
#!/bin/bash
set -euo pipefault

# Check PVC status
kubectl get pvc -n homelab

# Check PV status
kubectl get pv

# Describe PVC for errors
kubectl describe pvc app-data -n homelab

# Check storage directory on node
sudo ls -la /var/lib/rancher/k3s/storage/

# Increase PVC size
kubectl patch pvc app-data -n homelab \
    -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

## Best Practices

1. **Use Namespaces** - Separate prod, dev, monitoring
2. **Resource Limits** - Set memory/CPU requests and limits
3. **Health Checks** - Implement liveness and readiness probes
4. **Persistent Storage** - Use PVCs for data that must survive pod restarts
5. **ConfigMaps & Secrets** - Externalize configuration from images
6. **RBAC** - Limit service account permissions
7. **Security Context** - Run containers as non-root
8. **Update Strategy** - Use rolling deployments for zero-downtime updates
9. **Monitoring** - Deploy Prometheus/Grafana for visibility
10. **Backups** - Backup etcd (cluster state) and persistent data regularly

## Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Awesome K3s](https://github.com/rootsongjc/awesome-k3s)
- [K8s Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

---

✅ **You now have a production-grade Kubernetes setup with K3s, ready for deploying containerized homelab services!**
