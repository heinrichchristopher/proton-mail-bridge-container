FROM debian:trixie-slim

ARG BRIDGE_VERSION
ARG TARGETARCH=amd64

LABEL org.opencontainers.image.title="Proton Mail Bridge"
LABEL org.opencontainers.image.description="Proton Mail Bridge (headless) listening on 0.0.0.0 for SMTP/IMAP"
LABEL org.opencontainers.image.source="https://github.com/heinrichchristopher/proton-mail-bridge-container"
LABEL org.opencontainers.image.version="${BRIDGE_VERSION}"

# Bridge itself always binds to 127.0.0.1:1025/1143 - socat forwards the
# externally reachable ports to it.
ENV BRIDGE_SMTP_PORT=1025 \
    BRIDGE_IMAP_PORT=1143 \
    LISTEN_SMTP_PORT=2025 \
    LISTEN_IMAP_PORT=2143 \
    HOME=/data

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg pass socat tini procps; \
    curl -fsSL -o /tmp/bridge.deb \
        "https://proton.me/download/bridge/protonmail-bridge_${BRIDGE_VERSION}-1_${TARGETARCH}.deb"; \
    apt-get install -y --no-install-recommends /tmp/bridge.deb; \
    rm -f /tmp/bridge.deb; \
    apt-get purge -y curl; apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*; \
    # Unraid default user: nobody (99) / users (100)
    mkdir -p /data; chown 99:100 /data; chmod 700 /data

COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

USER 99:100
WORKDIR /data
VOLUME /data
EXPOSE 2025 2143

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD pgrep -f 'protonmail/bridge/bridge' >/dev/null && pgrep socat >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
CMD ["run"]
