FROM eclipse-temurin:21-jre-alpine AS base

RUN apk --no-cache add \
    curl \
    ca-certificates \
    tzdata \
    dumb-init \
    && rm -rf /var/cache/apk/*

RUN addgroup -g 1001 nyxis && \
    adduser -D -u 1001 -G nyxis -s /bin/sh nyxis

RUN mkdir -p /app/lib /app/logs /app/config /app/tmp && \
    chown -R nyxis:nyxis /app && \
    chmod 755 /app && \
    chmod 755 /app/lib /app/config && \
    chmod 775 /app/logs /app/tmp

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+OptimizeStringConcat" \
    SPRING_PROFILES_ACTIVE="" \
    TZ=UTC \
    APP_HOME=/app \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /app

USER nyxis

EXPOSE 8080 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["dumb-init", "--"]

LABEL org.opencontainers.image.title="Nyxis Backend Base Image" \
      org.opencontainers.image.description="Production-ready base image for Nyxis Backend Spring Boot applications" \
      org.opencontainers.image.vendor="Nyxis" \
      org.opencontainers.image.source="https://github.com/your-org/nyxis-base-images" \
      org.opencontainers.image.base.name="eclipse-temurin:21-jre-alpine"