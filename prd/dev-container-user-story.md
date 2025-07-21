# User Story: Nyxis Development Container

## Epic
**Development Infrastructure**

## Story
**As a** software developer  
**I want** a comprehensive, consistent development container environment for Nyxis  
**So that** I can develop, test, and debug all three components (backend, node, CLI) with full toolchain support and AI-powered development assistance

## Background
The Nyxis platform consists of three distinct components built with different technologies: a Java Spring Boot backend, a Java Spring Boot node agent, and a Go CLI application. The development container must provide a unified environment supporting multi-language development, security tools, and modern development workflows including Claude Code integration.

## Requirements

### Functional Requirements

#### F1: Multi-Language Development Support
- **MUST** include Java 21 JDK (Eclipse Temurin) for Spring Boot development
- **MUST** include Go 1.24+ for CLI development
- **MUST** include Maven 3.9.11+ for Java build management
- **MUST** include Node.js 18+ for tooling and Claude Code support
- **MUST** support concurrent development of all three components

#### F2: Claude Code Integration
- **MUST** include Claude Code CLI pre-installed and configured
- **MUST** support Claude Code authentication and workspace integration
- **MUST** provide seamless AI-powered development assistance
- **MUST** maintain Claude Code configuration persistence across container rebuilds
- **SHOULD** include Claude Code best practices and shortcuts

#### F3: Development Tools
- **MUST** include comprehensive VS Code extension pack for all languages
- **MUST** include Git with GitHub CLI integration
- **MUST** include Docker-in-Docker for container operations
- **MUST** include debugging tools for Java and Go
- **MUST** include code formatting and linting tools
- **SHOULD** include performance profiling tools
- **SHOULD** include security scanning tools

#### F4: Security Tools (Development Safe)
- **MUST** include nmap for network discovery testing
- **MUST** include masscan for performance testing
- **MUST** include basic network utilities (curl, wget, telnet, netcat)
- **MUST** restrict tool usage to safe development networks only
- **SHOULD** include nikto for web application testing (localhost only)
- **SHOULD** include educational security tools for learning

#### F5: Database and Storage
- **MUST** support H2 database for backend development
- **MUST** include database management tools
- **MUST** support file persistence across container restarts
- **SHOULD** include database migration tools
- **SHOULD** support external database connections for testing

### Non-Functional Requirements

#### NF1: Developer Experience
- **MUST** provide fast container startup (<30 seconds)
- **MUST** support hot reload for all development frameworks
- **MUST** include comprehensive shell environment (Zsh with Oh My Zsh)
- **MUST** support multiple terminal sessions and workflows
- **MUST** provide clear status indicators for all services
- **SHOULD** include productivity shortcuts and aliases
- **SHOULD** support multiple workspace configurations

#### NF2: Performance
- **MUST** optimize for development workflow performance
- **MUST** support efficient file watching and compilation
- **MUST** provide adequate resource allocation for all tools
- **SHOULD** include build caching for faster rebuilds
- **SHOULD** optimize container layer caching
- **SHOULD** support parallel development operations

#### NF3: Consistency
- **MUST** provide identical environment across different host systems
- **MUST** support Windows, macOS, and Linux development hosts
- **MUST** maintain consistent tool versions and configurations
- **MUST** support reproducible development environments
- **SHOULD** include environment validation and health checks

#### NF4: Security
- **MUST** implement safe defaults for security tool usage
- **MUST** restrict network access to development networks only
- **MUST** include security best practices for development
- **MUST** support secure credential management
- **SHOULD** include security scanning for development dependencies
- **SHOULD** implement development environment sandboxing

#### NF5: Maintainability
- **MUST** support automated container updates
- **MUST** include clear documentation and setup instructions
- **MUST** provide troubleshooting guides and common solutions
- **SHOULD** include container health monitoring
- **SHOULD** support configuration drift detection

## Technical Specifications

### Base Image Architecture
```dockerfile
# Multi-stage approach for optimized caching
FROM mcr.microsoft.com/devcontainers/go:1-1.24-bullseye AS base

# Language runtimes and build tools
FROM base AS development-tools
# Java 21, Maven, Node.js, development utilities

FROM development-tools AS security-tools  
# Safe security tools for development use

FROM security-tools AS vscode-integration
# VS Code extensions and Claude Code setup
```

### Development Stack Components

#### Java Development
- **JDK**: Eclipse Temurin 21 with full JDK (not just JRE)
- **Build Tool**: Maven 3.9.11 with dependency caching
- **Spring Boot**: Support for 3.2.1+ and 3.5.0+
- **Testing**: JUnit 5, Testcontainers, WireMock
- **Debugging**: Java Debug Wire Protocol (JDWP) support

#### Go Development  
- **Runtime**: Go 1.24+ with module support
- **Tools**: gopls, delve debugger, staticcheck, goreleaser
- **Testing**: Built-in testing framework with coverage
- **Building**: Multi-platform build support
- **Debugging**: Delve integration with VS Code

#### Node.js Ecosystem
- **Runtime**: Node.js 18 LTS
- **Package Manager**: npm with global packages
- **Claude Code**: Pre-installed `@anthropic-ai/claude-code`
- **Utilities**: Development and build tools

### VS Code Integration

#### Core Extensions
```json
[
  "ms-vscode.vscode-java-pack",
  "vscjava.vscode-spring-boot-dashboard", 
  "golang.go",
  "ms-azuretools.vscode-docker",
  "eamodio.gitlens",
  "github.vscode-pull-request-github"
]
```

#### Development Extensions
- Spring Boot Developer Pack
- Java debugging and testing tools
- Go development tools with debugging
- Docker and container support
- Git integration and pull request management
- Markdown and documentation tools

#### Settings Configuration
```json
{
  "java.home": "/usr/lib/jvm/temurin-21-jdk-amd64",
  "go.goroot": "/usr/local/go",
  "terminal.integrated.defaultProfile.linux": "zsh"
}
```

### Service Architecture

#### Port Mapping
- **18081**: Backend API (maps to container 8080)
- **18082**: Node Health/API (maps to container 8080)  
- **18083**: Additional development port
- **5005**: Java Debug Port (backend)
- **5006**: Java Debug Port (node)

#### Volume Mounts
- **Source Code**: `/workspace` (bind mount)
- **Go Modules**: Persistent volume for module cache
- **VS Code Extensions**: Persistent volume for extensions
- **Claude Config**: `~/.config/claude-code` (read-only bind)
- **SSH Keys**: `~/.ssh` (read-only bind)

### Directory Structure
```
/workspace/
├── backend/           # Spring Boot backend
├── node/             # Spring Boot node agent  
├── cli/              # Go CLI application
├── docs/             # Documentation
├── scripts/          # Development scripts
└── .devcontainer/    # Container configuration
```

## Acceptance Criteria

### AC1: Multi-Language Development
- [ ] All three components (backend, node, CLI) build successfully
- [ ] Hot reload works for Java Spring Boot applications
- [ ] Go development tools function properly with debugging
- [ ] Maven dependencies resolve and cache properly
- [ ] Cross-component integration testing works

### AC2: Claude Code Integration
- [ ] Claude Code is pre-installed and globally available
- [ ] Authentication workflow is documented and functional
- [ ] Claude Code workspace integration works seamlessly
- [ ] Configuration persists across container rebuilds
- [ ] AI-powered development features are accessible

### AC3: Developer Experience
- [ ] Container starts in under 30 seconds
- [ ] All VS Code extensions load properly
- [ ] Terminal environment is fully configured with Zsh
- [ ] File watching and hot reload perform adequately
- [ ] Multiple development workflows can run concurrently

### AC4: Security and Safety
- [ ] Security tools are restricted to safe development use
- [ ] Network access is limited to development networks
- [ ] No production or public network scanning capabilities
- [ ] Security best practices are documented and enforced
- [ ] Safe defaults prevent accidental misuse

### AC5: Consistency and Reliability
- [ ] Environment is identical across different host systems
- [ ] Tool versions are locked and reproducible
- [ ] Container rebuilds are fast with effective caching
- [ ] Documentation is comprehensive and up-to-date
- [ ] Troubleshooting guides cover common issues

## Dependencies
- Docker Desktop or compatible container runtime
- VS Code with Dev Containers extension
- Host system with adequate resources (8GB+ RAM recommended)
- Network connectivity for package downloads and Claude Code
- GitHub access for repository operations

## Security Considerations

### Development Safety
- Security tools configured for localhost and RFC 1918 networks only
- No public internet scanning capabilities
- Educational use only with clear safety guidelines
- Network traffic monitoring and logging

### Credential Management
- SSH key mounting (read-only)
- Claude Code configuration binding
- Git credential helper integration
- Secure environment variable handling

### Container Security
- Non-root user execution (vscode user)
- Minimal privilege escalation
- Security scanning of container dependencies
- Regular base image updates

## Out of Scope
- Production deployment configurations
- External database server setup
- Production security tools or offensive capabilities
- Network infrastructure or VPN configuration
- CI/CD pipeline integration (separate container)
- Performance benchmarking tools

## Definition of Done
- [ ] All three Nyxis components build and run successfully
- [ ] Claude Code integration is functional and documented
- [ ] VS Code development experience is smooth and responsive
- [ ] Security tools work safely within development constraints
- [ ] Container startup time meets performance requirements
- [ ] Documentation is complete with setup and troubleshooting guides
- [ ] Multi-platform support (Intel/ARM Mac, Linux, Windows WSL)
- [ ] Container can be rebuilt reliably with proper caching

## Usage Examples

### Starting Development Environment
```bash
# Open project in VS Code
code .

# VS Code will prompt to "Reopen in Container"
# Or use Command Palette: "Dev Containers: Reopen in Container"
```

### Development Workflow
```bash
# Terminal 1: Backend development
cd backend && mvn spring-boot:run

# Terminal 2: Node development  
cd node && mvn spring-boot:run

# Terminal 3: CLI development
cd cli && go run . --help

# Terminal 4: Claude Code assistance
claude
```

### Claude Code Integration
```bash
# Authenticate Claude Code (one-time setup)
claude auth login

# Use Claude Code for development assistance
claude "Help me implement a new API endpoint"
claude "Review this Go function for potential improvements"
claude "Generate unit tests for this Java service"
```

## Notes
- Container designed for development workflow optimization
- Emphasizes safety and educational use of security tools
- Claude Code integration enhances AI-powered development
- Multi-language support requires careful resource management
- Regular updates needed for tool versions and security patches