#!/usr/bin/with-contenv bash

# Read config from Home Assistant
CONFIG_PATH="/data/options.json"

if [ -f "$CONFIG_PATH" ]; then
    CALIBRE_LIBRARY_PATH=$(jq -r '.calibre_library_path // "/media/Books/Calibre"' "$CONFIG_PATH")

    # Create symlink from CWA's expected path to user's library path
    echo "[custom-init] Creating symlink: /calibre-library -> ${CALIBRE_LIBRARY_PATH}"
    ln -sf "${CALIBRE_LIBRARY_PATH}" /calibre-library

    # Export environment variables
    export TZ=$(jq -r '.timezone // "UTC"' "$CONFIG_PATH")
    export NETWORK_SHARE_MODE=$(jq -r '.network_share_mode // false' "$CONFIG_PATH")

    # Export Hardcover token if provided
    HARDCOVER_TOKEN=$(jq -r '.hardcover_token // ""' "$CONFIG_PATH")
    if [ -n "$HARDCOVER_TOKEN" ]; then
        export HARDCOVER_TOKEN
    fi

    echo "[custom-init] Configuration loaded successfully"
else
    echo "[custom-init] No config file found, using defaults"
    ln -sf "/media/Books/Calibre" /calibre-library
fi
