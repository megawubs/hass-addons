# Upstream publishes a distroless image, which has no shell and therefore no
# way to render the Home Assistant add-on options into a config file. So we
# lift the static binaries out of it and run them on the Home Assistant base
# image, which gives us bashio and s6-overlay.
ARG OPDS_PROXY_VERSION=0.3.3
FROM ghcr.io/evan-buss/opds-proxy:${OPDS_PROXY_VERSION} AS upstream

# Pinned on purpose: since Supervisor 2026.04.0 the BUILD_FROM argument is no
# longer supplied, so the base image has to be named here.
FROM ghcr.io/home-assistant/base:3.24-2026.06.1

ARG BUILD_VERSION

# Used to generate the persistent cookie signing keys.
RUN apk add --no-cache openssl

# opds-proxy and kepubify are both static Go binaries, so they run fine on
# musl. kindlegen is deliberately left behind: upstream only ships a 32-bit
# glibc build of it. Without kindlegen present opds-proxy skips the MOBI
# conversion and serves the original EPUB instead, which is what we want.
COPY --from=upstream /opds-proxy /usr/bin/opds-proxy
COPY --from=upstream /usr/local/bin/kepubify /usr/bin/kepubify

COPY rootfs /

RUN chmod a+x /usr/bin/opds-proxy /usr/bin/kepubify \
    && find /etc/s6-overlay/s6-rc.d -type f \( -name run -o -name up -o -name finish \) \
        -exec chmod a+x {} +

# Replaces the config.yaml `watchdog` option, which the add-on linter rejects
# in favour of a native health check. curl comes from the base image.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS -o /dev/null http://127.0.0.1:8080/ || exit 1

LABEL \
    io.hass.name="OPDS Proxy" \
    io.hass.description="Browse and download from your OPDS libraries on any eReader" \
    io.hass.type="app" \
    io.hass.arch="aarch64|amd64" \
    io.hass.version="${BUILD_VERSION}"
