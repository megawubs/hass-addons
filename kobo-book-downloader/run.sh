#!/bin/bash
set -e

echo "[kobo-book-downloader] Starting Kobo Book Downloader addon..."

# Read configuration
DOWNLOAD_PATH=$(jq -r '.download_path // "/media/kobo-books"' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

# Persistent storage. The `addon_config` map mounts at /addon_config (NOT /config),
# so kobodl.json must live here — otherwise the login/config is written to the
# container's ephemeral layer and is lost on every restart.
KOBODL_CONFIG="/addon_config/kobodl.json"

echo "[kobo-book-downloader] Download path: $DOWNLOAD_PATH"
echo "[kobo-book-downloader] Config file: $KOBODL_CONFIG"
echo "[kobo-book-downloader] Log level: $LOG_LEVEL"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_PATH"

# Start the kobodl web server. kobodl reads/writes its config via the --config
# flag; the path is read at startup and written on login.
echo "[kobo-book-downloader] Starting web interface on port 5000..."
exec kobodl --config "$KOBODL_CONFIG" serve --host 0.0.0.0 --port 5000 --output-dir "$DOWNLOAD_PATH"
