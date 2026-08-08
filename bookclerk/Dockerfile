# Multi-stage build: bookclerk has no published upstream image, so this
# clones the pinned commit and compiles the daemon/CLI, the two mandatory
# helper binaries (bookclerk-media-worker, bookclerk-jail), the first-party
# source plugins (audible/libro/chirp/graphicaudio) via the project's own
# `cargo stage-plugins` tooling, and the React web UI.
#
# Bumping the pinned commit:
#   1. Get a new SHA from https://github.com/fritz-fritz/bookclerk/commits/main
#   2. Update BOOKCLERK_REF below
#   3. Bump `version:` in config.yaml (that's what triggers a Supervisor/CI rebuild)

ARG BOOKCLERK_REF=60263a4ded3b7db934cdef6fb6406e5cc8c937c7

FROM alpine/git AS source
ARG BOOKCLERK_REF
RUN git clone https://github.com/fritz-fritz/bookclerk /app \
    && cd /app \
    && git checkout "$BOOKCLERK_REF"

FROM node:20-bookworm AS ui
WORKDIR /app
COPY --from=source /app/ui/package.json /app/ui/package-lock.json ./
RUN npm ci
COPY --from=source /app/ui ./
RUN npm run build

FROM rust:1.85-bookworm AS builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential pkg-config libssl-dev clang cmake \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=source /app ./
# Core binaries. Neither helper is optional: bookclerk-media-worker runs codec
# jobs and bookclerk-jail confines plugin guests — bookclerkd refuses to do
# either unconfined when they're missing.
RUN cargo build --release \
        -p bookclerk-cli -p bookclerkd -p bookclerk-media-worker -p bookclerk-jail
# First-party source plugins (external guests), built+staged with upstream's
# own tooling rather than hand-rolled `plugin.toml` copying.
RUN cargo stage-plugins --release
RUN strip target/release/bookclerk target/release/bookclerkd \
        target/release/bookclerk-media-worker target/release/bookclerk-jail

FROM debian:bookworm-slim AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates bash jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/bookclerk /usr/local/bin/bookclerk
COPY --from=builder /app/target/release/bookclerkd /usr/local/bin/bookclerkd
COPY --from=builder /app/target/release/bookclerk-media-worker /usr/local/bin/bookclerk-media-worker
COPY --from=builder /app/target/release/bookclerk-jail /usr/local/bin/bookclerk-jail
# Read-only bundled plugins, separate from /data (the mutable, HA-managed
# per-add-on volume) so a fresh /data on first install doesn't start with an
# empty plugins/ directory.
COPY --from=builder /app/target/plugin-artifacts /opt/bookclerk/plugins
COPY --from=ui /app/dist /opt/bookclerk/ui-dist
COPY --from=source /app/config/config.example.toml /etc/bookclerk/config.example.toml

ENV BOOKCLERK_FILES_DIR=/data \
    BOOKCLERK_CONFIG=/data/config.toml \
    BOOKCLERK_DAEMON_LISTEN=0.0.0.0:8787 \
    BOOKCLERK_PLUGIN_DIRS=/opt/bookclerk/plugins \
    BOOKCLERK_UI_DIST=/opt/bookclerk/ui-dist \
    BOOKCLERK_OUTPUT_LOCAL_ROOT=/media/Audiobooks \
    BOOKCLERK_PLUGIN_ISOLATION=best-effort

COPY rootfs/ /
RUN chmod +x /run.sh

EXPOSE 8787
WORKDIR /data
CMD ["/run.sh"]
