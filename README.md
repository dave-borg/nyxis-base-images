# Nyxis Base Images

Production-ready Docker base images for the Nyxis penetration testing platform.

## Overview

This repository contains optimized, secure Docker base images for the Nyxis platform components:

- **backend-base**: Production Spring Boot 3.5.0 runtime (Java 21)
- **cli-base**: Ultra-minimal Go 1.23.6 static binary runtime
- **node-base**: Hardened penetration testing tools runtime with network safety
- **devcontainer**: Comprehensive multi-language development environment

## Quick Start

### Pull Pre-built Images

```bash
# Backend base image
docker pull ghcr.io/your-org/backend-base:latest

# CLI base image  
docker pull ghcr.io/your-org/cli-base:latest

# Node base image (security tools)
docker pull ghcr.io/your-org/node-base:latest

# Development container
docker pull ghcr.io/your-org/devcontainer:latest
```

### Build Locally

```bash
# Build all images
./scripts/build-all.sh

# Build specific image
./scripts/build-all.sh backend-base

# Build and push to registry
./scripts/push-all.sh
```

### Test with Docker Compose

```bash
# Start all test services
docker-compose up -d

# Test specific image
docker-compose up backend-base

# View logs
docker-compose logs -f
```

## Images

### Backend Base (`backend-base`)

**Purpose**: Production-ready runtime for Nyxis Backend Spring Boot applications

**Base**: Eclipse Temurin 21 JRE Alpine  
**Size**: <100MB  
**User**: nyxis (UID 1001)

**Features**:
- Java 21 JRE optimized for containers
- Non-root execution with proper permissions
- Health check support
- Signal handling with dumb-init
- Timezone data and CA certificates

**Ports**: 8080 (API), 8081 (Management)

**Usage**:
```dockerfile
FROM ghcr.io/your-org/backend-base:latest
COPY target/nyxis-backend.jar /app/lib/app.jar
CMD ["java", "-jar", "/app/lib/app.jar"]
```

### CLI Base (`cli-base`)

**Purpose**: Ultra-minimal runtime for Nyxis CLI Go applications

**Base**: Scratch  
**Size**: <10MB  
**User**: Built-in nobody

**Features**:
- Minimal attack surface (scratch base)
- CA certificates for HTTPS
- Timezone data embedded
- Static binary execution

**Usage**:
```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o nyxis ./cmd/cli

FROM ghcr.io/your-org/cli-base:latest
COPY --from=builder /app/nyxis /nyxis
```

### Node Base (`node-base`)

**Purpose**: Hardened runtime for Nyxis Node with penetration testing tools

**Base**: Eclipse Temurin 21 JRE Alpine + Security Tools  
**Size**: <500MB  
**User**: nyxis (UID 1001)

**Security Tools**:
- nmap (network discovery)
- masscan (port scanning)
- nikto (web vulnerability scanning)
- nuclei (vulnerability detection)
- gobuster (directory enumeration)

**Safety Features**:
- Network validation (private IPs only)
- Tool sandboxing
- Safe target validation script

**Usage**:
```dockerfile
FROM ghcr.io/your-org/node-base:latest
COPY target/nyxis-node.jar /app/lib/app.jar
CMD ["java", "-jar", "/app/lib/app.jar"]
```

**Network Safety**:
```bash
# Validate target before scanning
validate-target 192.168.1.1  #  Allowed
validate-target 8.8.8.8      #  Blocked (public IP)
```

### Development Container (`devcontainer`)

**Purpose**: Comprehensive development environment for all Nyxis components

**Base**: Microsoft Dev Containers Go + Multi-language tools  
**Size**: ~2GB  
**User**: vscode (UID 1000)

**Development Stack**:
- Java 21 JDK (Spring Boot development)
- Go 1.24+ (CLI development)
- Maven 3.9.11+ (build management)
- Node.js 18+ (tooling)
- Claude Code CLI (AI assistance)

**VS Code Integration**:
- Pre-configured extensions
- Language server support
- Debugging capabilities
- Git integration

**Usage with VS Code**:
```bash
# Open project in container
code .
# VS Code will prompt: "Reopen in Container"
```

**Development Workflow**:
```bash
# Terminal 1: Backend
cd backend && mvn spring-boot:run

# Terminal 2: Node  
cd node && mvn spring-boot:run

# Terminal 3: CLI
cd cli && go run . --help

# Terminal 4: AI assistance
claude "help me implement a new API endpoint"
```

## Build System

### Version Management

The build system uses semantic versioning with Git tags:

```bash
# Get current version
./scripts/version.sh version

# Get Docker tags  
./scripts/version.sh tags
```

**Version Strategy**:
- `v1.0.0` � `v1.0.0`, `1.0.0`, `v1.0`, `v1`, `latest`
- `main` branch � `latest`, `edge`
- Development � `v1.0.0-dev.5.abc123`

### Build Scripts

**Build All Images**:
```bash
./scripts/build-all.sh [OPTIONS] [IMAGE_NAME]

# Examples
./scripts/build-all.sh                    # Build all locally
./scripts/build-all.sh --push             # Build and push all
./scripts/build-all.sh backend-base       # Build specific image
./scripts/build-all.sh --registry my.registry.com --push
```

**Push to Registry**:
```bash
./scripts/push-all.sh [OPTIONS] [IMAGE_NAME]

# GitHub Container Registry authentication
export GITHUB_TOKEN=your_token
export GITHUB_ACTOR=your_username
./scripts/push-all.sh
```

### CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/build-images.yml`) provides:

**Triggers**:
- Push to `main` branch � Build and push with `latest` tag
- Git tags `v*` � Build and push with semantic version tags
- Pull requests � Build and test only
- Manual dispatch � Configurable build options

**Security**:
- Trivy vulnerability scanning
- SARIF security reports
- SBOM (Software Bill of Materials) generation
- Multi-platform builds (AMD64, ARM64)

**Testing**:
- Functional tests for each image
- Health check validation
- Tool availability verification

## Security

### Vulnerability Scanning

All images are scanned with Trivy:

```bash
# Scan specific image
trivy image ghcr.io/your-org/backend-base:latest

# Scan all images
for image in backend-base cli-base node-base devcontainer; do
  trivy image ghcr.io/your-org/$image:latest
done
```

### Network Safety (Node Image)

The node-base image includes network safety validation:

**Allowed Networks** (Private RFC 1918):
- `10.0.0.0/8` (10.x.x.x)
- `172.16.0.0/12` (172.16-31.x.x)  
- `192.168.0.0/16` (192.168.x.x)
- `127.0.0.0/8` (localhost)

**Blocked Networks**:
- Public IP addresses
- Internet-routable ranges
- Cloud provider metadata endpoints

### Best Practices

- **Non-root execution**: All production images run as non-root users
- **Minimal attack surface**: Only essential packages included
- **Read-only filesystem**: Supports read-only root filesystem
- **Security scanning**: Automated vulnerability assessment
- **Supply chain security**: SBOM generation and dependency tracking

## Local Development

### Prerequisites

- Docker 20.10+ with BuildKit
- Docker Compose 3.8+
- Git 2.30+
- Bash 4.0+

### Testing

```bash
# Test all images
docker-compose up -d
docker-compose ps
docker-compose logs

# Test specific image
docker-compose up backend-base
docker-compose exec backend-base java -version

# Test development container
docker-compose up devcontainer
docker-compose exec devcontainer development-safety-check
```

### Customization

**Environment Variables**:
```bash
export REGISTRY=my.registry.com/myorg
export PLATFORMS=linux/amd64
export VERSION=v1.2.3
./scripts/build-all.sh --push
```

**Docker Compose Override**:
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  backend-base:
    environment:
      - CUSTOM_ENV=value
    ports:
      - "9080:8080"
```

## Troubleshooting

### GitHub Actions Issues

**SARIF Upload Permissions Error**:
```
Resource not accessible by integration - https://docs.github.com/rest
```

This occurs when the repository doesn't have the required permissions for security events. Solutions:

1. **Use the simple workflow**: 
   ```bash
   # Go to Actions tab and run "Simple Build and Push" workflow
   # This workflow skips security scanning and focuses on building
   ```

2. **Enable repository permissions**:
   - Go to Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

3. **Alternative: Manual security scanning**:
   ```bash
   # Build images locally and scan
   ./scripts/build-all.sh
   trivy image backend-base:latest
   ```

**Multi-architecture Build Issues**:
```bash
# If builds fail on ARM64, test locally first
docker buildx create --use
docker buildx build --platform linux/amd64 -f dockerfiles/backend-base.Dockerfile .
```

### Common Issues

**Build failures**:
```bash
# Clear BuildKit cache
docker buildx prune -f

# Rebuild without cache
./scripts/build-all.sh --no-cache
```

**Registry authentication**:
```bash
# Manual GitHub Container Registry login
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Verify authentication
docker pull ghcr.io/your-org/backend-base:latest
```

**Security tool restrictions**:
```bash
# Test network validation in node image
docker run --rm ghcr.io/your-org/node-base:latest validate-target 192.168.1.1
docker run --rm ghcr.io/your-org/node-base:latest validate-target 8.8.8.8
```

### Health Checks

```bash
# Check image health
docker run --rm ghcr.io/your-org/backend-base:latest curl -f http://localhost:8080/actuator/health

# Verify tool availability
docker run --rm ghcr.io/your-org/node-base:latest nmap --version
docker run --rm ghcr.io/your-org/devcontainer:latest java -version
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes locally
4. Ensure security scans pass
5. Submit a pull request

### Development Workflow

```bash
# Make changes to Dockerfiles
vim dockerfiles/backend-base.Dockerfile

# Test locally
./scripts/build-all.sh backend-base
docker-compose up backend-base

# Test security
trivy image backend-base:latest

# Submit changes
git commit -m "feat: improve backend base image security"
git push origin feature-branch
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/your-org/nyxis-base-images/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/nyxis-base-images/discussions)
- **Security**: Report security issues via [GitHub Security](https://github.com/your-org/nyxis-base-images/security)