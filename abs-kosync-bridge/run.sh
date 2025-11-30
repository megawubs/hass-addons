#!/bin/bash

set -e

# Read config from Home Assistant
CONFIG_PATH="/data/options.json"

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
