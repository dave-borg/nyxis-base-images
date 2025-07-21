# User Story: Nyxis CLI Production Base Image

Image should be called 'cli-base'

## Epic
**Production Container Infrastructure**

## Story
**As a** DevOps engineer  
**I want** an ultra-minimal, secure production-ready base image for the Nyxis CLI  
**So that** I can deploy CLI operations in containerized environments with maximum security and minimal resource footprint

## Background
The Nyxis CLI is a Go 1.23.6 application that provides command-line interface capabilities for managing penetration testing engagements. It requires an extremely lightweight container base optimized for CLI operations with minimal dependencies and maximum security.

## Requirements

### Functional Requirements

#### F1: Go Runtime Support
- **MUST** support statically compiled Go 1.23.6 binaries
- **MUST** include minimal C library for CGO dependencies (if any)
- **MUST** support cross-platform binary execution (AMD64, ARM64)
- **SHOULD** be compatible with scratch or distroless base images

#### F2: System Dependencies
- **MUST** include ca-certificates for HTTPS/TLS connections
- **MUST** include timezone data for global operations
- **MUST** support SSL/TLS certificate validation
- **SHOULD** include minimal shell for operational tasks (if not using scratch)
- **SHOULD NOT** include unnecessary system utilities or packages

#### F3: CLI Operations
- **MUST** support file I/O operations for configuration and output
- **MUST** support network connectivity for API communication
- **MUST** handle signal processing for graceful shutdown
- **SHOULD** support stdin/stdout/stderr redirection
- **SHOULD** support environment variable processing

#### F4: User Security
- **MUST** run as non-root user (if not using scratch)
- **MUST** have minimal filesystem permissions
- **MUST** support read-only root filesystem
- **MUST NOT** include shells, package managers, or debug tools

### Non-Functional Requirements

#### NF1: Security
- **MUST** be based on minimal distribution (scratch, distroless, or Alpine)
- **MUST** have zero known vulnerabilities
- **MUST** contain only essential files and libraries
- **MUST** support security scanning and validation
- **MUST** implement principle of least privilege
- **SHOULD** support immutable filesystem operations

#### NF2: Performance
- **MUST** be ultra-lightweight (<10MB total image size)
- **MUST** have instant startup time (<1 second)
- **MUST** support multi-platform builds (AMD64, ARM64)
- **MUST** minimize memory footprint (<50MB runtime)
- **SHOULD** optimize for container orchestration scenarios

#### NF3: Portability
- **MUST** work in kubernetes, docker, and podman environments
- **MUST** support CI/CD pipeline execution
- **MUST** work in air-gapped and restricted environments
- **SHOULD** support serverless container platforms
- **SHOULD** work in embedded and edge computing scenarios

#### NF4: Operational
- **MUST** follow semantic versioning for image tags
- **MUST** include minimal build metadata
- **MUST** support automated vulnerability scanning
- **SHOULD** be built using multi-stage Docker builds
- **SHOULD** support reproducible builds

## Technical Specifications

### Base Image Strategy

#### Option 1: Scratch Base (Preferred)
```dockerfile
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/passwd /etc/passwd
COPY nyxis /nyxis
USER nobody
ENTRYPOINT ["/nyxis"]
```

#### Option 2: Distroless Base (Alternative)  
```dockerfile
FROM gcr.io/distroless/static:nonroot
COPY nyxis /nyxis
ENTRYPOINT ["/nyxis"]
```

#### Option 3: Alpine Minimal (Fallback)
```dockerfile  
FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata
RUN adduser -D -s /bin/sh nyxis
USER nyxis
COPY nyxis /usr/local/bin/nyxis
ENTRYPOINT ["/usr/local/bin/nyxis"]
```

### Directory Structure (Minimal)
```
/
├── etc/
│   ├── ssl/certs/ca-certificates.crt
│   └── passwd                 # User information (if needed)
├── usr/share/zoneinfo/        # Timezone data
└── nyxis                      # CLI binary
```

### Environment Variables
- `TZ`: Timezone configuration (default: UTC)
- `HOME`: User home directory (default: /)
- `PATH`: Binary path (if using non-scratch)

### CLI Dependencies (Go modules)
Based on go.mod analysis:
- `github.com/spf13/cobra`: CLI framework
- `github.com/spf13/viper`: Configuration management  
- `github.com/go-resty/resty/v2`: HTTP client
- `github.com/gorilla/websocket`: WebSocket communication
- `github.com/fatih/color`: Terminal colors
- `gopkg.in/yaml.v3`: YAML processing

### Build Requirements
- Static compilation with CGO disabled
- Embedded timezone data
- Embedded CA certificates
- Minimal binary size optimization

## Acceptance Criteria

### AC1: Size and Performance
- [ ] Total image size is less than 10MB
- [ ] Container startup time is less than 1 second
- [ ] Binary is statically compiled with no external dependencies
- [ ] Supports both AMD64 and ARM64 architectures
- [ ] Memory usage is less than 50MB during normal operation

### AC2: Security Compliance
- [ ] Image passes security vulnerability scan with zero issues
- [ ] Contains no unnecessary files, packages, or utilities
- [ ] Supports read-only root filesystem
- [ ] Runs with minimal privileges (non-root if not scratch)
- [ ] No shell access or debug capabilities

### AC3: Functionality
- [ ] CLI binary executes without errors
- [ ] Network connectivity works for API calls
- [ ] Configuration file processing works correctly
- [ ] Output formatting and colors work properly
- [ ] Signal handling and graceful shutdown work

### AC4: Operational Readiness
- [ ] Image builds reproducibly across environments
- [ ] Supports container orchestration platforms
- [ ] Works in CI/CD pipeline environments
- [ ] Compatible with security-restricted environments
- [ ] Proper image tagging and metadata

## Dependencies
- Go 1.23.6 compiler for static binary compilation
- CA certificates bundle for HTTPS connectivity
- Timezone database for time operations
- Docker BuildKit for multi-stage builds
- Container registry for image storage

## Build Strategy

### Multi-Stage Build Process
1. **Builder Stage**: Compile Go binary with static linking
2. **CA Certificates Stage**: Extract certificate bundle
3. **Timezone Stage**: Extract timezone data  
4. **Final Stage**: Assemble minimal runtime image

### Compilation Flags
```bash
CGO_ENABLED=0 GOOS=linux go build \
  -a -installsuffix cgo \
  -ldflags '-w -s -extldflags "-static"' \
  -o nyxis main.go
```

### Size Optimization
- Strip debug symbols (-s -w flags)
- Use UPX compression if beneficial
- Minimize embedded resources
- Remove unused Go packages

## Security Considerations

### Minimal Attack Surface
- No shell or system utilities
- No package managers or installers
- No unnecessary libraries or dependencies
- Minimal filesystem content

### Runtime Security  
- Read-only root filesystem support
- Non-root user execution (when possible)
- No privilege escalation capabilities
- Minimal network surface area

### Supply Chain Security
- Reproducible builds with locked dependencies
- Vulnerability scanning of all components
- Signed container images
- Minimal external dependencies

## Out of Scope
- Interactive shell capabilities
- System administration tools
- Development or debugging utilities
- Package managers or installers
- GUI applications or display support
- Complex runtime dependencies

## Definition of Done
- [ ] Base image builds successfully across all target platforms
- [ ] Security scan results show zero vulnerabilities
- [ ] Image size meets ultra-lightweight requirements (<10MB)
- [ ] Performance benchmarks exceed specified requirements
- [ ] CLI functionality works correctly in containerized environment
- [ ] Documentation includes usage examples and best practices
- [ ] Image is published to container registry with proper tagging
- [ ] Integration tests pass with actual Nyxis CLI application

## Notes
- This base image will be consumed by the Nyxis CLI application Dockerfile
- Extreme minimalism is prioritized for security and performance
- Consider scratch base for maximum security and minimal size
- Binary must be completely self-contained with static compilation
- Regular rebuilds required for CA certificate and timezone updates