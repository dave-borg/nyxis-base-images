#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_SCRIPT="${SCRIPT_DIR}/version.sh"

REGISTRY="${REGISTRY:-ghcr.io/dave-borg}"
BUILDX_BUILDER="${BUILDX_BUILDER:-nyxis-builder}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

# Image to Dockerfile mapping (bash 3.2 compatible)
IMAGES="backend-base:dockerfiles/backend-base.Dockerfile cli-base:dockerfiles/cli-base.Dockerfile node-base:dockerfiles/node-base.Dockerfile devcontainer:dockerfiles/devcontainer.Dockerfile devcontainer-simple:dockerfiles/devcontainer-simple.Dockerfile"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

setup_buildx() {
    if ! docker buildx inspect "${BUILDX_BUILDER}" >/dev/null 2>&1; then
        log "Creating buildx builder: ${BUILDX_BUILDER}"
        docker buildx create --name "${BUILDX_BUILDER}" --driver docker-container --bootstrap
    fi
    docker buildx use "${BUILDX_BUILDER}"
}

get_build_args() {
    local version
    version=$("${VERSION_SCRIPT}" version)
    
    echo "--build-arg VERSION=${version}"
    echo "--build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "--build-arg VCS_REF=$(git rev-parse HEAD)"
}

build_image() {
    local image_name="$1"
    local dockerfile="$2"
    local version
    local tags
    local build_args
    
    version=$("${VERSION_SCRIPT}" version)
    tags=$("${VERSION_SCRIPT}" tags)
    build_args=$(get_build_args)
    
    log "Building ${image_name}:${version}"
    log "Dockerfile: ${dockerfile}"
    log "Platforms: ${PLATFORMS}"
    
    local tag_args=""
    for tag in ${tags}; do
        tag_args="${tag_args} --tag ${REGISTRY}/${image_name}:${tag}"
    done
    
    if [ "${PUSH:-false}" = "true" ]; then
        log "Building and pushing ${image_name}"
        local action="--push"
    else
        log "Building ${image_name} locally"
        local action="--load"
    fi
    
    # Build the image
    docker buildx build \
        --file "${dockerfile}" \
        --platform "${PLATFORMS}" \
        ${tag_args} \
        ${build_args} \
        --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --label "org.opencontainers.image.version=${version}" \
        --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
        ${action} \
        "${PROJECT_ROOT}"
    
    log "✅ Successfully built ${image_name}:${version}"
}

build_all() {
    log "Starting build process"
    log "Registry: ${REGISTRY}"
    log "Platforms: ${PLATFORMS}"
    log "Push: ${PUSH:-false}"
    
    setup_buildx
    
    for image_spec in $IMAGES; do
        image_name="${image_spec%%:*}"
        dockerfile="${image_spec#*:}"
        log "Building ${image_name}..."
        build_image "${image_name}" "${dockerfile}"
    done
    
    log "✅ All images built successfully"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [IMAGE_NAME]

Build Nyxis base Docker images.

OPTIONS:
    -h, --help          Show this help message
    -p, --push          Push images to registry after building
    -r, --registry REG  Set registry (default: ${REGISTRY})
    --platforms PLAT    Set platforms (default: ${PLATFORMS})
    --builder NAME      Set buildx builder name (default: ${BUILDX_BUILDER})

IMAGE_NAME:
    backend-base        Build only backend base image
    cli-base           Build only CLI base image  
    node-base          Build only node base image
    devcontainer       Build only development container
    devcontainer-simple Build only simple development container (OpenJDK fallback)
    (no argument)      Build all images

EXAMPLES:
    $0                           # Build all images locally
    $0 --push                    # Build and push all images
    $0 backend-base              # Build only backend-base locally
    $0 --push cli-base           # Build and push only cli-base
    $0 --registry my.registry.com --push  # Use custom registry

ENVIRONMENT VARIABLES:
    REGISTRY           Container registry (default: ghcr.io/your-org)
    PLATFORMS          Target platforms (default: linux/amd64,linux/arm64)
    BUILDX_BUILDER     Buildx builder name (default: nyxis-builder)
    PUSH               Set to 'true' to push images
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -p|--push)
                export PUSH=true
                shift
                ;;
            -r|--registry)
                export REGISTRY="$2"
                shift 2
                ;;
            --platforms)
                export PLATFORMS="$2"
                shift 2
                ;;
            --builder)
                export BUILDX_BUILDER="$2"
                shift 2
                ;;
            backend-base|cli-base|node-base|devcontainer|devcontainer-simple)
                local image_name="$1"
                local dockerfile=""
                
                # Find dockerfile for the given image name
                for image_spec in $IMAGES; do
                    if [ "${image_spec%%:*}" = "$image_name" ]; then
                        dockerfile="${image_spec#*:}"
                        break
                    fi
                done
                
                if [ -z "$dockerfile" ]; then
                    log "Error: Unknown image name: $image_name"
                    exit 1
                fi
                setup_buildx
                build_image "$image_name" "$dockerfile"
                exit 0
                ;;
            *)
                log "Error: Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    build_all
}

cd "${PROJECT_ROOT}"
main "$@"