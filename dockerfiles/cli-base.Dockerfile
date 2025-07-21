FROM alpine:3.19 AS builder

RUN apk --no-cache add ca-certificates tzdata && \
    update-ca-certificates

RUN echo 'nobody:x:65534:65534:nobody:/:/sbin/nologin' > /tmp/passwd

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /tmp/passwd /etc/passwd

USER 65534:65534

ENV TZ=UTC \
    HOME=/ \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/nyxis"]

LABEL org.opencontainers.image.title="Nyxis CLI Base Image" \
      org.opencontainers.image.description="Ultra-minimal base image for Nyxis CLI Go applications" \
      org.opencontainers.image.vendor="Nyxis" \
      org.opencontainers.image.source="https://github.com/your-org/nyxis-base-images" \
      org.opencontainers.image.base.name="scratch"