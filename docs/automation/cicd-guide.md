# 🚀 CI/CD Pipeline Setup for Homelab #automation #ci-cd #gitea #drone #github-actions

Self-hosted continuous integration and deployment pipelines for your homelab infrastructure. Learn to automate builds, tests, and deployments using open-source tools like Gitea Actions, Drone CI, and Jenkins.

## Table of Contents
- [CI/CD Concepts](#cicd-concepts)
- [Self-Hosted Options Comparison](#self-hosted-options-comparison)
- [Gitea Actions Setup](#gitea-actions-setup)
- [Basic Pipeline Examples](#basic-pipeline-examples)
- [Drone CI Setup](#drone-ci-setup)
- [Webhooks and Secrets](#webhooks-and-secrets)
- [Docker Container Deployment](#docker-container-deployment)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## CI/CD Concepts

CI/CD automates the pipeline from code commit to production deployment:
- **Continuous Integration (CI)**: Automatically build and test code on every push
- **Continuous Deployment (CD)**: Automatically deploy tested code to production
- **Workflows**: Defined as YAML files in your repository
- **Runners**: Agents that execute pipeline jobs

## Self-Hosted Options Comparison

| Tool | Setup | Language | Resource Use | Best For |
|------|-------|----------|--------------|----------|
| Gitea Actions | Simple | YAML | Low | Git hosting + CI together |
| Drone CI | Moderate | YAML | Low-Medium | Lightweight, Docker-native |
| Jenkins | Complex | Groovy/YAML | High | Enterprise-grade, flexible |
| GitHub Actions | Simple | YAML | Cloud-only | Public projects, managed |

## Gitea Actions Setup

Gitea is a lightweight self-hosted Git service with built-in CI/CD.

**Install Gitea with PostgreSQL:**
```bash
# Create directories
mkdir -p /opt/gitea/data /opt/gitea/config /opt/gitea/logs
cd /opt/gitea

# Create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    ports:
      - "3000:3000"
      - "2222:22"
    volumes:
      - ./data:/data
      - ./config:/etc/gitea
      - ./logs:/var/log/gitea
    environment:
      - GITEA_WORK_DIR=/data
      - GITEA_CUSTOM=/data/gitea
    restart: always

  postgres:
    image: postgres:15-alpine
    container_name: gitea-db
    environment:
      POSTGRES_DB: gitea
      POSTGRES_USER: gitea
      POSTGRES_PASSWORD: your_secure_password
    volumes:
      - ./postgres:/var/lib/postgresql/data
    restart: always

networks:
  default:
    name: gitea-network
EOF

docker-compose up -d
```

**Configure Gitea Actions Runner:**
```bash
# Create runner directory
mkdir -p /opt/gitea-runner
cd /opt/gitea-runner

# Create docker-compose for runner
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  runner:
    image: gitea/act_runner:latest
    container_name: gitea-runner
    environment:
      GITEA_INSTANCE_URL: http://gitea:3000
      GITEA_RUNNER_REGISTRATION_TOKEN: your_token_here
      GITEA_RUNNER_NAME: runner-1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
    restart: always
    depends_on:
      - gitea
    networks:
      - gitea-network

networks:
  gitea-network:
    external: true
EOF

docker-compose up -d
```

**Get registration token (in Gitea web UI):**
Navigate to: Admin → Actions → Runners → Create New Runner

## Basic Pipeline Examples

**Simple Node.js Build and Test Pipeline (.gitea/workflows/build.yml):**
```yaml
name: Build and Test
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run linter
        run: npm run lint || true

      - name: Run tests
        run: npm test

      - name: Build application
        run: npm run build

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: build-artifacts
          path: dist/
```

**Docker Build and Push Pipeline (.gitea/workflows/docker.yml):**
```yaml
name: Build Docker Image
on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Docker image
        run: |
          docker build -t myapp:latest \
            -t myapp:${{ github.sha }} .

      - name: Test container
        run: |
          docker run --rm myapp:latest /bin/sh -c "echo 'Container works!'"

      - name: Tag and push to registry
        env:
          REGISTRY_URL: registry.example.com
        run: |
          docker tag myapp:latest $REGISTRY_URL/myapp:latest
          docker tag myapp:${{ github.sha }} $REGISTRY_URL/myapp:${{ github.sha }}
          docker push $REGISTRY_URL/myapp:latest
          docker push $REGISTRY_URL/myapp:${{ github.sha }}
```

**Multi-stage Pipeline with Deployment (.gitea/workflows/full-pipeline.yml):**
```yaml
name: Full CI/CD Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: ./scripts/test.sh

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build application
        run: ./scripts/build.sh
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: app-build
          path: build/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to server
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          DEPLOY_HOST: homelab.local
          DEPLOY_USER: deploy
        run: |
          mkdir -p ~/.ssh
          echo "$DEPLOY_KEY" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -H $DEPLOY_HOST >> ~/.ssh/known_hosts
          ssh -i ~/.ssh/deploy_key $DEPLOY_USER@$DEPLOY_HOST \
            "cd /opt/myapp && docker-compose pull && docker-compose up -d"
```

## Drone CI Setup

Drone is a minimal, language-agnostic CI/CD platform.

**Install Drone with Docker:**
```bash
mkdir -p /opt/drone
cd /opt/drone

cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  drone-server:
    image: drone/drone:latest
    container_name: drone-server
    ports:
      - "8080:80"
    volumes:
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      DRONE_GITEA_SERVER: http://gitea:3000
      DRONE_GITEA_CLIENT_ID: your_client_id
      DRONE_GITEA_CLIENT_SECRET: your_client_secret
      DRONE_RPC_SECRET: your_rpc_secret
      DRONE_SERVER_HOST: drone.homelab.local
      DRONE_SERVER_PROTO: http
    restart: always

  drone-runner:
    image: drone/drone-runner-docker:latest
    container_name: drone-runner
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      DRONE_RPC_HOST: drone-server
      DRONE_RPC_PROTO: http
      DRONE_RPC_SECRET: your_rpc_secret
      DRONE_RUNNER_CAPACITY: 2
      DRONE_RUNNER_NAME: runner-1
    restart: always
    depends_on:
      - drone-server

networks:
  default:
    name: drone-network
EOF

docker-compose up -d
```

**Drone Pipeline (.drone.yml):**
```yaml
kind: pipeline
type: docker
name: default

steps:
  - name: build
    image: golang:1.20
    commands:
      - go get
      - go build -o app

  - name: test
    image: golang:1.20
    commands:
      - go test -v ./...

  - name: publish
    image: plugins/docker
    settings:
      repo: registry.homelab.local/myapp
      tags:
        - latest
        - ${DRONE_COMMIT_SHA:0:7}
    when:
      branch: main
      event: push

trigger:
  branch:
    - main
    - develop
```

## Webhooks and Secrets

**Create webhook in Gitea:**
1. Go to repository → Settings → Webhooks
2. Add webhook with URL: `http://gitea-runner:3000/api/actions/webhook`
3. Select events: Push events, Pull requests
4. Webhook automatically triggers pipeline on code push

**Add secrets to Gitea Actions:**
```bash
# Via UI: Repository → Settings → Actions → Secrets
# Add secret named: DEPLOY_KEY
# Add secret named: REGISTRY_PASSWORD
```

**Use secrets in workflow:**
```yaml
- name: Deploy with secret
  env:
    SECRET_KEY: ${{ secrets.DEPLOY_KEY }}
  run: |
    ssh-keygen -p -N "" -m pem -f $HOME/.ssh/id_rsa
    echo "$SECRET_KEY" > ~/.ssh/deploy_key
    chmod 600 ~/.ssh/deploy_key
```

## Docker Container Deployment

**Dockerfile for Python app:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]
```

**Pipeline that builds and deploys Docker container:**
```yaml
name: Docker Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.sha }} .
          docker tag myapp:${{ github.sha }} myapp:latest

      - name: Run container tests
        run: |
          docker run --rm myapp:latest python -m pytest

      - name: Push to registry
        run: |
          docker push myapp:${{ github.sha }}
          docker push myapp:latest

      - name: Deploy to homelab
        env:
          DEPLOY_HOST: server.homelab.local
          DEPLOY_USER: ubuntu
        run: |
          cat > deploy.sh <<'SCRIPT'
          #!/bin/bash
          set -euo pipefail
          docker pull myapp:latest
          docker stop myapp || true
          docker rm myapp || true
          docker run -d \
            --name myapp \
            --restart always \
            -p 5000:5000 \
            myapp:latest
          SCRIPT

          ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$DEPLOY_HOST < deploy.sh
```

## Troubleshooting

**Runner not connecting:**
```bash
# Check runner logs
docker logs gitea-runner

# Verify connection
curl -H "Authorization: token YOUR_TOKEN" \
  http://gitea:3000/api/v1/user

# Check runner status
docker exec gitea-runner ./act_runner validate
```

**Pipeline not triggering:**
```bash
# Check webhook logs in Gitea
# Repository → Settings → Webhooks → Recent Deliveries

# Manual trigger test
curl -X POST http://gitea:3000/api/v1/repos/user/repo/dispatches \
  -H "Authorization: token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"event_type":"test"}'
```

**Secret not available in pipeline:**
```bash
# Verify secret exists
docker exec gitea psql -U gitea gitea -c \
  "SELECT name FROM action_secret WHERE name='SECRET_NAME';"

# Redeploy runner after adding secrets
docker-compose down && docker-compose up -d
```

## Best Practices

1. **Keep workflows simple** - Complex logic belongs in scripts, not YAML
2. **Use artifacts for debugging** - Upload logs and outputs from failures
3. **Implement timeouts** - Prevent hanging builds with `timeout-minutes`
4. **Security** - Never commit secrets, use secret management
5. **Cache dependencies** - Speed up builds by caching npm, pip, maven
6. **Separate concerns** - Use different jobs for test, build, deploy stages
7. **Environment-specific configs** - Use different secrets/vars per environment

## Additional Resources

- [Gitea Actions Documentation](https://docs.gitea.com/usage/actions/overview)
- [Drone CI Documentation](https://docs.drone.io/)
- [GitHub Actions Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Docker Hub Registry](https://hub.docker.com)
- [Self-Hosted Registry with Docker](https://docs.docker.com/registry/deploying/)

---

✅ Created comprehensive CI/CD guide covering Gitea Actions, Drone CI, Docker deployment, and production-ready pipeline examples for homelab infrastructure.
