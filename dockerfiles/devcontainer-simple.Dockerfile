FROM mcr.microsoft.com/devcontainers/go:1-1.24-bullseye AS base

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
        groupmod --gid $USER_GID $USERNAME \
        && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
        && chown -R $USER_UID:$USER_GID /home/$USERNAME; \
    fi

FROM base AS java-tools

# Use OpenJDK from Debian repositories as fallback
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-21-jdk \
        maven \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV MAVEN_HOME=/usr/share/maven

FROM java-tools AS node-tools

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code typescript ts-node

FROM node-tools AS security-tools

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nmap \
        curl \
        wget \
        unzip \
        telnet \
        netcat-openbsd \
        dnsutils \
        iproute2 \
        iputils-ping \
        openssl \
        python3 \
        python3-pip \
        perl \
        libpcap-dev \
        build-essential \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install requests beautifulsoup4 && \
    rm -rf /root/.cache

WORKDIR /tmp

RUN git clone --depth 1 https://github.com/sullo/nikto.git && \
    chmod +x nikto/program/nikto.pl && \
    ln -s /tmp/nikto/program/nikto.pl /usr/local/bin/nikto

RUN curl -L "https://github.com/robertdavidgraham/masscan/archive/refs/heads/master.tar.gz" | tar xz && \
    cd masscan-master && \
    make -j$(nproc) && \
    make install

RUN echo "Downloading nuclei binary..." && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -L "https://github.com/projectdiscovery/nuclei/releases/download/v3.3.6/nuclei_3.3.6_linux_${ARCH}.zip" -o nuclei.zip && \
    unzip nuclei.zip && \
    mv nuclei /usr/local/bin/nuclei && \
    chmod +x /usr/local/bin/nuclei && \
    rm -f nuclei.zip README.md LICENSE.md README_*.md && \
    echo "Nuclei download complete"

RUN echo "Building gobuster from source..." && \
    git clone --depth 1 https://github.com/OJ/gobuster.git /tmp/gobuster-src && \
    cd /tmp/gobuster-src && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -trimpath -o /usr/local/bin/gobuster . && \
    rm -rf /tmp/gobuster-src && \
    echo "Gobuster build complete"

COPY <<'EOF' /usr/local/bin/validate-target
#!/bin/bash
TARGET="$1"

if [[ -z "$TARGET" ]]; then
    echo "Error: No target specified" >&2
    exit 1
fi

if [[ "$TARGET" =~ ^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.|::1|localhost) ]]; then
    echo "✓ Target '$TARGET' is in allowed development network range"
    exit 0
fi

echo "✗ Error: Target '$TARGET' is not in allowed private network ranges (development only)" >&2
echo "Allowed ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, ::1, localhost" >&2
exit 1
EOF

RUN chmod +x /usr/local/bin/validate-target

FROM security-tools AS vscode-integration

USER $USERNAME

RUN mkdir -p /home/$USERNAME/.config/git && \
    echo '[include]\n    path = ~/.gitconfig-shared' > /home/$USERNAME/.config/git/config

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends gh && \
    sudo rm -rf /var/lib/apt/lists/*

RUN if [ ! -d "/home/$USERNAME/.oh-my-zsh" ]; then \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
    fi && \
    echo 'export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"' >> /home/$USERNAME/.zshrc && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> /home/$USERNAME/.zshrc && \
    echo 'export MAVEN_HOME=/usr/share/maven' >> /home/$USERNAME/.zshrc && \
    echo 'alias ll="ls -la"' >> /home/$USERNAME/.zshrc && \
    echo 'alias validate-target="/usr/local/bin/validate-target"' >> /home/$USERNAME/.zshrc && \
    echo 'alias safe-nmap="validate-target \$1 && nmap"' >> /home/$USERNAME/.zshrc && \
    echo 'alias safe-masscan="validate-target \$1 && masscan"' >> /home/$USERNAME/.zshrc

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        docker.io \
        docker-compose \
    && rm -rf /var/lib/apt/lists/* && \
    usermod -aG docker $USERNAME

COPY <<'EOF' /usr/local/bin/development-safety-check
#!/bin/bash
echo "🔒 Nyxis Development Container Safety Check"
echo "=========================================="
echo "✓ Security tools are restricted to private networks only"
echo "✓ Use 'validate-target <ip>' to check if a target is safe"
echo "✓ Use 'safe-nmap' and 'safe-masscan' aliases for safe scanning"
echo "✓ All tools configured for educational/development use only"
echo ""
echo "Allowed target ranges:"
echo "  • 10.0.0.0/8 (10.x.x.x)"
echo "  • 172.16.0.0/12 (172.16-31.x.x)"
echo "  • 192.168.0.0/16 (192.168.x.x)"
echo "  • 127.0.0.0/8 (localhost)"
echo ""
echo "⚠️  DO NOT scan public IP addresses or networks you don't own!"
EOF

RUN chmod +x /usr/local/bin/development-safety-check

ENV SHELL=/bin/zsh
ENV CLAUDE_CONFIG_DIR=/home/$USERNAME/.config/claude-code

USER $USERNAME

WORKDIR /workspace

ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["sleep", "infinity"]

LABEL org.opencontainers.image.title="Nyxis Development Container (Simple)" \
      org.opencontainers.image.description="Simplified development environment using Debian OpenJDK" \
      org.opencontainers.image.vendor="Nyxis" \
      org.opencontainers.image.source="https://github.com/your-org/nyxis-base-images" \
      org.opencontainers.image.base.name="mcr.microsoft.com/devcontainers/go:1-1.24-bullseye"