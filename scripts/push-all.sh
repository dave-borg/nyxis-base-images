#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPT="${SCRIPT_DIR}/build-all.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

check_registry_auth() {
    local registry="${1:-ghcr.io}"
    
    log "Checking authentication for registry: ${registry}"
    
    if ! docker info | grep -q "Registry:"; then
        log "Warning: Docker daemon registry info not available"
    fi
    
    if ! docker pull hello-world >/dev/null 2>&1; then
        log "Warning: Unable to verify Docker registry connectivity"
    fi
    
    if [[ "${registry}" == "ghcr.io"* ]]; then
        if [ -z "${GITHUB_TOKEN:-}" ] && [ -z "${CR_PAT:-}" ]; then
            log "Warning: No GitHub token found. Set GITHUB_TOKEN or CR_PAT environment variable."
            log "To authenticate with GitHub Container Registry:"
            log "  export GITHUB_TOKEN=your_token"
            log "  echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
        fi
    fi
}

github_login() {
    local token="${GITHUB_TOKEN:-${CR_PAT:-}}"
    local username="${GITHUB_ACTOR:-${GITHUB_USERNAME:-}}"
    
    if [ -n "${token}" ] && [ -n "${username}" ]; then
        log "Authenticating with GitHub Container Registry..."
        echo "${token}" | docker login ghcr.io -u "${username}" --password-stdin
        log "✅ Successfully authenticated with GitHub Container Registry"
    else
        log "⚠️  No GitHub credentials found. Manual authentication may be required."
        log "To authenticate manually:"
        log "  echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
    fi
}

push_images() {
    local registry="${REGISTRY:-ghcr.io/your-org}"
    
    log "Starting push process to registry: ${registry}"
    
    check_registry_auth "${registry}"
    
    if [[ "${registry}" == "ghcr.io"* ]]; then
        github_login
    fi
    
    log "Building and pushing all images..."
    
    export PUSH=true
    export REGISTRY="${registry}"
    
    "${BUILD_SCRIPT}" "$@"
    
    log "✅ All images pushed successfully to ${registry}"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [IMAGE_NAME]

Build and push Nyxis base Docker images to container registry.

This script is a wrapper around build-all.sh that automatically enables 
push mode and handles registry authentication.

OPTIONS:
    -h, --help          Show this help message
    -r, --registry REG  Set registry (default: ghcr.io/your-org)
    --platforms PLAT    Set platforms (default: linux/amd64,linux/arm64)
    --builder NAME      Set buildx builder name (default: nyxis-builder)

IMAGE_NAME:
    backend-base        Push only backend base image
    cli-base           Push only CLI base image  
    node-base          Push only node base image
    devcontainer       Push only development container
    (no argument)      Push all images

EXAMPLES:
    $0                                    # Build and push all images
    $0 backend-base                       # Build and push only backend-base
    $0 --registry my.registry.com         # Use custom registry
    
GITHUB CONTAINER REGISTRY AUTHENTICATION:
    Set one of these environment variables:
    - GITHUB_TOKEN (recommended for GitHub Actions)
    - CR_PAT (Classic Personal Access Token)
    
    Also set:
    - GITHUB_ACTOR or GITHUB_USERNAME (your GitHub username)
    
    Manual authentication:
    echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

ENVIRONMENT VARIABLES:
    REGISTRY           Container registry (default: ghcr.io/your-org)
    PLATFORMS          Target platforms (default: linux/amd64,linux/arm64)
    BUILDX_BUILDER     Buildx builder name (default: nyxis-builder)
    GITHUB_TOKEN       GitHub token for GHCR authentication
    CR_PAT             GitHub Classic PAT for GHCR authentication
    GITHUB_ACTOR       GitHub username for authentication
    GITHUB_USERNAME    Alternative GitHub username variable
EOF
}

main() {
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            push_images "$@"
            ;;
    esac
}

main "$@"