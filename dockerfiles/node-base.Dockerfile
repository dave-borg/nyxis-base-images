FROM alpine:3.19 AS tool-builder

RUN apk --no-cache add \
    build-base \
    git \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/cache/apk/*

WORKDIR /tmp

RUN curl -L "https://github.com/robertdavidgraham/masscan/archive/refs/heads/master.tar.gz" | tar xz && \
    cd masscan-master && \
    make -j$(nproc) && \
    make install DESTDIR=/opt/masscan

RUN git clone --depth 1 https://github.com/projectdiscovery/nuclei.git && \
    cd nuclei && \
    go mod download && \
    go build -o /opt/nuclei/bin/nuclei ./cmd/nuclei

RUN curl -L "https://github.com/OJ/gobuster/releases/latest/download/gobuster-linux-amd64.tar.gz" | tar xz && \
    mkdir -p /opt/gobuster/bin && \
    mv gobuster-linux-amd64/gobuster /opt/gobuster/bin/

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
    openssl \
    libpcap \
    bind-tools \
    netcat-openbsd \
    && rm -rf /var/cache/apk/*

RUN pip3 install --no-cache-dir requests beautifulsoup4 && \
    rm -rf /root/.cache

RUN curl -L "https://cirt.net/nikto/nikto-2.5.0.tar.gz" | tar xz -C /opt && \
    mv /opt/nikto-2.5.0 /opt/nikto && \
    chmod +x /opt/nikto/program/nikto.pl

COPY --from=tool-builder /opt/masscan/usr/local/bin/masscan /opt/tools/bin/masscan
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