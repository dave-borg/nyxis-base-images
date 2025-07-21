# User Story: Nyxis Node Production Base Image

## Epic
**Production Container Infrastructure**

## Story
**As a** DevOps engineer  
**I want** a secure, hardened production-ready base image for the Nyxis Node  
**So that** I can deploy node agents with penetration testing tools while maintaining security isolation and minimal attack surface

## Background
The Nyxis Node is a Spring Boot 3.2.1 application built on Java 21 that executes penetration testing commands in isolated environments. It requires a specialized container base that includes essential security tools while maintaining strict security boundaries and network safety validation.

## Requirements

### Functional Requirements

#### F1: Java Runtime Environment
- **MUST** include Eclipse Temurin JRE 21 (OpenJDK 21)
- **MUST** be optimized for containerized JVM workloads
- **MUST** support Spring Boot 3.2.1 runtime requirements
- **MUST** include timezone data for global deployment

#### F2: Security Tools
- **MUST** include nmap (Network Mapper) for network discovery
- **MUST** include masscan for high-speed port scanning
- **MUST** include nikto for web vulnerability scanning
- **MUST** include nuclei for vulnerability detection
- **MUST** include gobuster for directory/file enumeration
- **SHOULD** include basic network utilities (ping, telnet, netcat, curl, wget)
- **SHOULD** include SSL/TLS tools (openssl, nmap ssl scripts)

#### F3: System Dependencies  
- **MUST** include libpcap for packet capture capabilities
- **MUST** include Python 3 for tool dependencies and custom scripts
- **MUST** include Perl for nikto and other tool dependencies
- **MUST** include essential build tools for tool compilation
- **MUST** include ca-certificates for HTTPS/TLS connections
- **SHOULD** include dumb-init for proper signal handling

#### F4: User Security
- **MUST** run as non-root user `nyxis` (UID 1001) 
- **MUST** create dedicated group `nyxis` (GID 1001)
- **MUST** provide controlled privilege escalation for specific tools only
- **MUST** implement strict file permissions for tool directories
- **MUST NOT** provide general sudo access

### Non-Functional Requirements

#### NF1: Security
- **MUST** be based on hardened Linux distribution (Alpine Linux preferred)
- **MUST** implement network safety validation for command execution
- **MUST** have no known high/critical CVEs at build time
- **MUST** isolate security tools from application runtime
- **MUST** support read-only root filesystem where possible
- **MUST** implement tool sandboxing capabilities
- **SHOULD** support mandatory access controls (AppArmor/SELinux)

#### NF2: Performance
- **MUST** be optimized for fast container startup (<15 seconds)
- **MUST** have reasonable image size (<500MB uncompressed)
- **MUST** support multi-platform builds (AMD64, ARM64)
- **SHOULD** include JVM performance tuning for containers
- **SHOULD** optimize tool loading and execution times

#### NF3: Network Safety
- **MUST** implement IP address validation (RFC 1918 private ranges only)
- **MUST** block commands targeting public IP addresses
- **MUST** include network safety validation utilities
- **MUST** support configurable network restrictions
- **SHOULD** implement DNS resolution controls
- **SHOULD** support network traffic monitoring

#### NF4: Observability
- **MUST** support health check endpoints
- **MUST** include proper signal handling for graceful shutdown
- **MUST** support structured logging for tool execution
- **MUST** provide tool execution audit capabilities
- **SHOULD** include performance monitoring for tools
- **SHOULD** support external monitoring integration

#### NF5: Operational
- **MUST** follow semantic versioning for image tags
- **MUST** include build metadata and tool versions
- **MUST** support automated vulnerability scanning
- **SHOULD** be built using multi-stage Docker builds
- **SHOULD** support immutable deployments

## Technical Specifications

### Base Image Requirements
```dockerfile
# Preferred approach: Multi-stage build
FROM alpine:3.19 as tool-builder
# Tool compilation and setup

FROM eclipse-temurin:21-jre-alpine as runtime
# Final runtime image
```

### Security Tools Installation
```bash
# Core scanning tools
apk add nmap nmap-scripts
apk add masscan  
apk add nikto
apk add nuclei
apk add gobuster

# Dependencies
apk add libpcap-dev python3 perl openssl
```

### Directory Structure
```
/app/
├── lib/                    # Application JAR
├── logs/                   # Log output directory  
├── config/                 # Configuration files
├── tools/                  # Security tool binaries
│   ├── nmap/              # Nmap and scripts
│   ├── masscan/           # Masscan binary
│   ├── nikto/             # Nikto installation
│   ├── nuclei/            # Nuclei templates
│   └── gobuster/          # Gobuster binary
└── tmp/                   # Temporary execution files
```

### Environment Variables
- `JAVA_OPTS`: JVM configuration options
- `SPRING_PROFILES_ACTIVE`: Spring Boot profiles  
- `TZ`: Timezone configuration (default: UTC)
- `APP_HOME`: Application directory (default: /app)
- `TOOLS_HOME`: Security tools directory (default: /app/tools)
- `NYXIS_NETWORK_VALIDATION`: Network safety mode (default: strict)

### Exposed Ports
- `8080`: HTTP API/Health check port
- No external scanning ports (tools run internally)

### Tool Capabilities
- **nmap**: Network discovery, port scanning, service detection
- **masscan**: High-speed port scanning
- **nikto**: Web server vulnerability scanning  
- **nuclei**: Template-based vulnerability detection
- **gobuster**: Directory and file enumeration

## Acceptance Criteria

### AC1: Security Compliance
- [ ] Image passes security vulnerability scan with zero high/critical issues
- [ ] All security tools are properly isolated and validated
- [ ] Network safety validation blocks public IP targeting
- [ ] Runs with minimal privileges and controlled tool access
- [ ] Supports read-only root filesystem mounting

### AC2: Tool Functionality
- [ ] All required security tools are installed and functional
- [ ] Tools can execute within containerized environment
- [ ] Network safety validation properly restricts tool usage
- [ ] Tool output is properly captured and logged
- [ ] Tool versions are current and vulnerability-free

### AC3: Performance Standards  
- [ ] Image size is less than 500MB uncompressed
- [ ] Container starts in less than 15 seconds with Spring Boot app
- [ ] Supports both AMD64 and ARM64 architectures
- [ ] Tool execution performance meets operational requirements

### AC4: Integration Testing
- [ ] Successfully runs Nyxis Node JAR without errors
- [ ] All security tools execute correctly in container
- [ ] Network safety validation blocks unauthorized targets
- [ ] Health endpoints respond correctly
- [ ] Audit logging captures tool execution properly

## Dependencies
- Eclipse Temurin JRE 21 or compatible OpenJDK distribution
- Alpine Linux 3.19+ with security tool packages
- nmap, masscan, nikto, nuclei, gobuster source/packages
- libpcap development libraries
- Python 3 and Perl runtime environments
- Docker BuildKit for multi-stage builds

## Security Considerations

### Network Safety
- Implement strict IP validation to prevent public internet scanning
- Support configurable allowlists for authorized target networks  
- Block DNS resolution to public domains
- Monitor and log all network activity

### Tool Isolation
- Run security tools with minimal required privileges
- Implement file system isolation for tool execution
- Validate all tool inputs and parameters
- Sandbox tool execution environments

### Container Security
- Use non-root user for all operations
- Implement read-only root filesystem
- Remove unnecessary packages and build tools
- Regular security scanning and updates

## Out of Scope
- Application code or JAR files (handled by application Dockerfile)
- Custom penetration testing scripts or payloads
- Database drivers or persistent storage tools
- Development tools or debugging utilities  
- GUI applications or display servers
- Network infrastructure or VPN capabilities

## Definition of Done
- [ ] Base image builds successfully across all target platforms
- [ ] Security scan results show zero high/critical vulnerabilities
- [ ] All security tools are functional and properly isolated
- [ ] Network safety validation prevents unauthorized scanning
- [ ] Performance benchmarks meet specified requirements
- [ ] Documentation includes tool usage and safety guidelines
- [ ] Image is published to container registry with proper tagging
- [ ] Integration tests pass with actual Nyxis Node application

## Notes
- This base image will be consumed by the Nyxis Node application Dockerfile
- Image must balance security tool availability with safety restrictions
- Consider implementing tool capability detection and validation
- Network safety is paramount - no public internet scanning allowed
- Regular updates required to maintain tool currency and security