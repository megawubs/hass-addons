#!/bin/bash

set -e

# Read config from Home Assistant to get books path
CONFIG_PATH="/data/options.json"
BOOKS_PATH=$(jq -r '.books_path // "/media/books"' "$CONFIG_PATH")

# Create necessary directories and symlinks for persistent storage
echo "[abs-kosync-bridge] Setting up storage directories"

# Ensure the configured books directory exists
mkdir -p "$BOOKS_PATH"

# Only create symlink if books_path is different from /books
if [ "$BOOKS_PATH" != "/books" ]; then
    # Remove /books if it exists (from base image) and create symlink
    rm -rf /books
    ln -sf "$BOOKS_PATH" /books
    echo "[abs-kosync-bridge] Created symlink: /books -> $BOOKS_PATH"
else
    echo "[abs-kosync-bridge] Using /books directory directly"
fi

# /data is automatically mounted by Home Assistant for addon persistent storage
echo "[abs-kosync-bridge] Storage directories ready"
echo "[abs-kosync-bridge]   Books: $BOOKS_PATH"
echo "[abs-kosync-bridge]   Data: /data (app data and cache)"

if [ -f "$CONFIG_PATH" ]; then
    echo "[abs-kosync-bridge] Reading configuration from Home Assistant"

    # Export required environment variables
    export ABS_SERVER=$(jq -r '.abs_server // ""' "$CONFIG_PATH")
    export ABS_KEY=$(jq -r '.abs_key // ""' "$CONFIG_PATH")
    export KOSYNC_SERVER=$(jq -r '.kosync_server // "http://homeassistant:7200"' "$CONFIG_PATH")
    export KOSYNC_USER=$(jq -r '.kosync_user // ""' "$CONFIG_PATH")
    export KOSYNC_KEY=$(jq -r '.kosync_key // ""' "$CONFIG_PATH")

    # Export optional configuration
    export SYNC_PERIOD_MINS=$(jq -r '.sync_period_mins // 5' "$CONFIG_PATH")
    export FUZZY_MATCH_THRESHOLD=$(jq -r '.fuzzy_match_threshold // 80' "$CONFIG_PATH")
    export SYNC_DELTA_ABS_SECONDS=$(jq -r '.sync_delta_abs_seconds // 30' "$CONFIG_PATH")
    export SYNC_DELTA_KOSYNC_PERCENT=$(jq -r '.sync_delta_kosync_percent // 1' "$CONFIG_PATH")
    export LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$CONFIG_PATH")

    # Save environment variables to a file so they're available when exec'ing into the container
    cat > /etc/profile.d/addon-env.sh << EOF
export ABS_SERVER="${ABS_SERVER}"
export ABS_KEY="${ABS_KEY}"
export KOSYNC_SERVER="${KOSYNC_SERVER}"
export KOSYNC_USER="${KOSYNC_USER}"
export KOSYNC_KEY="${KOSYNC_KEY}"
export SYNC_PERIOD_MINS="${SYNC_PERIOD_MINS}"
export FUZZY_MATCH_THRESHOLD="${FUZZY_MATCH_THRESHOLD}"
export SYNC_DELTA_ABS_SECONDS="${SYNC_DELTA_ABS_SECONDS}"
export SYNC_DELTA_KOSYNC_PERCENT="${SYNC_DELTA_KOSYNC_PERCENT}"
export LOG_LEVEL="${LOG_LEVEL}"
EOF

    echo "[abs-kosync-bridge] Configuration loaded successfully"
    echo "[abs-kosync-bridge] ABS_SERVER: ${ABS_SERVER}"
    echo "[abs-kosync-bridge] KOSYNC_SERVER: ${KOSYNC_SERVER}"
    echo "[abs-kosync-bridge] SYNC_PERIOD_MINS: ${SYNC_PERIOD_MINS}"
    echo "[abs-kosync-bridge] LOG_LEVEL: ${LOG_LEVEL}"
else
    echo "[abs-kosync-bridge] Warning: No config file found at $CONFIG_PATH"
fi

# Start the bridge
exec python src/main.py
