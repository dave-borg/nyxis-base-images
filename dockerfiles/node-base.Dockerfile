FROM golang:1.24-alpine AS tool-builder

RUN apk --no-cache add \
    build-base \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    linux-headers \
    libpcap-dev \
    && rm -rf /var/cache/apk/*

WORKDIR /tmp

RUN curl -L "https://github.com/robertdavidgraham/masscan/archive/refs/heads/master.tar.gz" | tar xz && \
    cd masscan-master && \
    make -j$(nproc) && \
    mkdir -p /opt/masscan/bin && \
    cp bin/masscan /opt/masscan/bin/masscan && \
    chmod +x /opt/masscan/bin/masscan

# Download nuclei binary for better reliability (avoid build timeouts)
RUN mkdir -p /opt/nuclei/bin && \
    echo "Downloading nuclei binary..." && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -L "https://github.com/projectdiscovery/nuclei/releases/download/v3.3.6/nuclei_3.3.6_linux_${ARCH}.zip" -o nuclei.zip && \
    unzip nuclei.zip && \
    mv nuclei /opt/nuclei/bin/nuclei && \
    chmod +x /opt/nuclei/bin/nuclei && \
    rm -f nuclei.zip README.md LICENSE.md && \
    echo "Nuclei download complete"

# Build gobuster from source (optimized for faster compilation)
RUN mkdir -p /opt/gobuster/bin && \
    echo "Building gobuster from source..." && \
    git clone --depth 1 https://github.com/OJ/gobuster.git /tmp/gobuster-src && \
    cd /tmp/gobuster-src && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -trimpath -o /opt/gobuster/bin/gobuster . && \
    chmod +x /opt/gobuster/bin/gobuster && \
    rm -rf /tmp/gobuster-src && \
    echo "Gobuster build complete"

FROM eclipse-temurin:21-jre-alpine AS runtime

RUN apk --no-cache add \
    curl \
    ca-certificates \
    tzdata \
    dumb-init \
    nmap \
    nmap-scripts \
    python3 \
    py3-pip \
    perl \
    nikto \
    openssl \
    libpcap \
    bind-tools \
    netcat-openbsd \
    git \
    && rm -rf /var/cache/apk/* \
    && ln -sf /usr/bin/nikto.pl /usr/bin/nikto

RUN pip3 install --break-system-packages --no-cache-dir requests beautifulsoup4 && \
    rm -rf /root/.cache

RUN git clone --depth 1 --branch master https://github.com/sullo/nikto.git /opt/nikto && \
    chmod +x /opt/nikto/program/nikto.pl

RUN mkdir -p /opt/tools/bin

COPY --from=tool-builder /opt/masscan/bin/masscan /opt/tools/bin/masscan
COPY --from=tool-builder /opt/nuclei/bin/nuclei /opt/tools/bin/nuclei
COPY --from=tool-builder /opt/gobuster/bin/gobuster /opt/tools/bin/gobuster

RUN addgroup -g 1001 nyxis && \
    adduser -D -u 1001 -G nyxis -s /bin/sh nyxis

RUN mkdir -p /app/lib /app/logs /app/config /app/tmp /app/tools && \
    chown -R nyxis:nyxis /app && \
    chmod 755 /app && \
    chmod 755 /app/lib /app/config /app/tools && \
    chmod 775 /app/logs /app/tmp

RUN ln -s /opt/tools/bin/* /usr/local/bin/ && \
    ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto

COPY <<'EOF' /usr/local/bin/validate-target
#!/bin/sh
TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Error: No target specified" >&2
    exit 1
fi

if echo "$TARGET" | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.|::1|localhost)' > /dev/null; then
    exit 0
fi

echo "Error: Target '$TARGET' is not in allowed private network ranges" >&2
exit 1
EOF

RUN chmod +x /usr/local/bin/validate-target

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC" \
    SPRING_PROFILES_ACTIVE="" \
    TZ=UTC \
    APP_HOME=/app \
    TOOLS_HOME=/app/tools \
    NYXIS_NETWORK_VALIDATION=strict \
    PATH="/usr/local/bin:/opt/tools/bin:$PATH"

WORKDIR /app

USER nyxis

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["dumb-init", "--"]

LABEL org.opencontainers.image.title="Nyxis Node Base Image" \
      org.opencontainers.image.description="Hardened base image for Nyxis Node with penetration testing tools" \
      org.opencontainers.image.vendor="Nyxis" \
      org.opencontainers.image.source="https://github.com/your-org/nyxis-base-images" \
      org.opencontainers.image.base.name="eclipse-temurin:21-jre-alpine"
