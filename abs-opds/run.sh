#!/bin/bash

set -e

# Read config from Home Assistant
CONFIG_PATH="/data/options.json"

if [ -f "$CONFIG_PATH" ]; then
    echo "[abs-opds-init] Reading configuration from Home Assistant"

    # Export environment variables that abs-opds expects
    export ABS_URL=$(jq -r '.abs_url // ""' "$CONFIG_PATH")
    export SHOW_AUDIOBOOKS=$(jq -r '.show_audiobooks // false' "$CONFIG_PATH")
    export SHOW_CHAR_CARDS=$(jq -r '.show_char_cards // false' "$CONFIG_PATH")
    export USE_PROXY=$(jq -r '.use_proxy // true' "$CONFIG_PATH")
    export PORT="3010"
    export OPDS_PAGE_SIZE=$(jq -r '.opds_page_size // 20' "$CONFIG_PATH")

    # OPDS_USERS is optional
    OPDS_USERS=$(jq -r '.opds_users // ""' "$CONFIG_PATH")
    if [ -n "$OPDS_USERS" ]; then
        export OPDS_USERS
    fi

    echo "[abs-opds-init] Configuration loaded successfully"
    echo "[abs-opds-init] ABS_URL: ${ABS_URL}"
    echo "[abs-opds-init] SHOW_AUDIOBOOKS: ${SHOW_AUDIOBOOKS}"
    echo "[abs-opds-init] USE_PROXY: ${USE_PROXY}"
else
    echo "[abs-opds-init] Warning: No config file found at $CONFIG_PATH"
fi

# Change to the app directory where npm start expects to run
cd /home/node/app

# Start the abs-opds server using npm start (same as original CMD)
exec npm start
