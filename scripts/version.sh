#!/bin/bash

set -euo pipefail

get_version() {
    if [ -n "${GITHUB_REF_NAME:-}" ] && [[ "${GITHUB_REF_NAME}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
        echo "${GITHUB_REF_NAME}"
        return 0
    fi

    if git describe --exact-match --tags HEAD 2>/dev/null; then
        return 0
    fi

    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    
    local commit_count
    commit_count=$(git rev-list --count "${latest_tag}..HEAD" 2>/dev/null || echo "1")
    
    local commit_sha
    commit_sha=$(git rev-parse --short HEAD)
    
    if [ "${commit_count}" = "0" ]; then
        echo "${latest_tag}"
    else
        echo "${latest_tag}-dev.${commit_count}.${commit_sha}"
    fi
}

get_docker_tags() {
    local version
    version=$(get_version)
    
    local tags="latest"
    
    if [[ "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        local semver="${version#v}"
        local major="${semver%%.*}"
        local minor="${semver#*.}"
        minor="${minor%.*}"
        
        tags="${tags} ${version} ${semver} v${major}.${minor} v${major}"
    else
        tags="${tags} ${version}"
    fi
    
    if [ "${GITHUB_REF_NAME:-}" = "main" ] || [ "${GITHUB_REF_NAME:-}" = "master" ]; then
        tags="${tags} edge"
    fi
    
    echo "${tags}"
}

case "${1:-version}" in
    "version")
        get_version
        ;;
    "tags")
        get_docker_tags
        ;;
    *)
        echo "Usage: $0 [version|tags]"
        exit 1
        ;;
esac