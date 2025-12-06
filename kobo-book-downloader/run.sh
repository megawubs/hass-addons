#!/bin/bash
set -e

echo "[kobo-book-downloader] Starting Kobo Book Downloader addon..."

# Read configuration
DOWNLOAD_PATH=$(jq -r '.download_path // "/media/kobo-books"' /data/options.json)
FORMAT_STR=$(jq -r '.format_str // "{Title}"' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

echo "[kobo-book-downloader] Download path: $DOWNLOAD_PATH"
echo "[kobo-book-downloader] Format string: $FORMAT_STR"
echo "[kobo-book-downloader] Log level: $LOG_LEVEL"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_PATH"

# Export environment variables for kobodl
export KOBODL_OUTPUT_DIR="$DOWNLOAD_PATH"
export KOBODL_CONFIG_DIR="/addon_config"

# Start the kobodl web server
echo "[kobo-book-downloader] Starting web interface on port 5000..."
exec kobodl --config /addon_config/kobodl.json serve --host 0.0.0.0 --port 5000 --output-dir "$DOWNLOAD_PATH" --fmt "$FORMAT_STR"
