# User Story: Nyxis Backend Production Base Image

## Epic
**Production Container Infrastructure**

## Story
**As a** DevOps engineer  
**I want** a minimal, secure production-ready base image for the Nyxis Backend  
**So that** I can deploy the backend service with optimal security, performance, and resource utilization

## Background
The Nyxis Backend is a Spring Boot 3.5.0 application built on Java 21 that serves as the central orchestration engine for penetration testing engagements. It requires a lightweight, hardened container base that supports JVM workloads while maintaining minimal attack surface.

## Requirements

### Functional Requirements

#### F1: Java Runtime Environment
- **MUST** include Eclipse Temurin JRE 21 (OpenJDK 21)
- **MUST** be optimized for containerized JVM workloads
- **MUST** support Spring Boot 3.5.0 runtime requirements
- **MUST** include timezone data for global deployment

#### F2: System Dependencies
- **MUST** include curl for health checks and external API calls
- **MUST** include ca-certificates for HTTPS/TLS connections
- **MUST** include minimal networking tools (ping, telnet, netcat)
- **SHOULD** include dumb-init for proper signal handling
- **SHOULD NOT** include build tools (Maven, compilation tools)

#### F3: User Security
- **MUST** run as non-root user `nyxis` (UID 1001)
- **MUST** create dedicated group `nyxis` (GID 1001)
- **MUST** set proper file permissions for application directories
- **MUST NOT** include sudo or privileged escalation tools

### Non-Functional Requirements

#### NF1: Security
- **MUST** be based on minimal Linux distribution (Alpine Linux preferred)
- **MUST** have no known high/critical CVEs at build time
- **MUST** include only essential packages to minimize attack surface
- **MUST** remove package managers and build tools from final image
- **MUST** implement read-only root filesystem capability
- **SHOULD** support security scanning with Trivy/Grype

#### NF2: Performance
- **MUST** be optimized for fast container startup (<10 seconds)
- **MUST** have minimal image size (<100MB uncompressed)
- **MUST** support multi-platform builds (AMD64, ARM64)
- **SHOULD** include JVM performance tuning for containers
- **SHOULD** support memory-constrained environments (512MB+)

#### NF3: Observability
- **MUST** support health check endpoints
- **MUST** include proper signal handling for graceful shutdown
- **MUST** support structured logging output
- **SHOULD** include JFR (Java Flight Recorder) capability
- **SHOULD** support external monitoring integration

#### NF4: Operational
- **MUST** follow semantic versioning for image tags
- **MUST** include build metadata and labels
- **MUST** support automated vulnerability scanning
- **SHOULD** be built using multi-stage Docker builds
- **SHOULD** support immutable deployments

## Technical Specifications

### Base Image Requirements
```dockerfile
# Preferred base: Eclipse Temurin Alpine
FROM eclipse-temurin:21-jre-alpine

# Alternative: Distroless Java
FROM gcr.io/distroless/java21-debian12
```

### Directory Structure
```
/app/
├── lib/                    # Application JAR
├── logs/                   # Log output directory
├── config/                 # Configuration files
└── tmp/                    # Temporary files
```

### Environment Variables
- `JAVA_OPTS`: JVM configuration options
- `SPRING_PROFILES_ACTIVE`: Spring Boot profiles
- `TZ`: Timezone configuration (default: UTC)
- `APP_HOME`: Application directory (default: /app)

### Exposed Ports
- `8080`: HTTP API port
- `8081`: Management/actuator port (optional)

### Resource Limits
- **Memory**: Optimized for 512MB-2GB heap
- **CPU**: Efficient resource utilization
- **Storage**: Minimal ephemeral storage requirements

## Acceptance Criteria

### AC1: Security Compliance
- [ ] Image passes security vulnerability scan with zero high/critical issues
- [ ] Runs as non-root user with minimal privileges
- [ ] Contains only essential packages and libraries
- [ ] Supports read-only root filesystem mounting

### AC2: Performance Standards
- [ ] Image size is less than 100MB uncompressed
- [ ] Container starts in less than 10 seconds with Spring Boot app
- [ ] Supports both AMD64 and ARM64 architectures
- [ ] JVM is optimized for container resource constraints

### AC3: Operational Readiness
- [ ] Includes proper health check support
- [ ] Supports graceful shutdown with signal handling
- [ ] Image is tagged with semantic versioning
- [ ] Build process is automated and repeatable

### AC4: Integration Testing
- [ ] Successfully runs Nyxis Backend JAR without errors
- [ ] Health endpoints respond correctly
- [ ] Logging output is structured and accessible
- [ ] Network connectivity works for external APIs

## Dependencies
- Eclipse Temurin JRE 21 or compatible OpenJDK distribution
- Alpine Linux 3.19+ or Debian 12+ (for distroless)
- Docker BuildKit for multi-stage builds
- Container registry for image storage

## Out of Scope
- Application code or JAR files (handled by application Dockerfile)
- Database drivers or specific backend dependencies
- Security tools or penetration testing utilities
- Development tools or debugging utilities
- Frontend assets or web servers

## Definition of Done
- [ ] Base image builds successfully across all target platforms
- [ ] Security scan results show zero high/critical vulnerabilities
- [ ] Performance benchmarks meet specified requirements
- [ ] Documentation includes usage examples and best practices
- [ ] Image is published to container registry with proper tagging
- [ ] Integration tests pass with actual Nyxis Backend application

## Notes
- This base image will be consumed by the Nyxis Backend application Dockerfile
- Image should be generic enough to support multiple Spring Boot applications
- Consider using multi-stage builds to minimize final image size
- Implement automated rebuilds when base image security updates are available