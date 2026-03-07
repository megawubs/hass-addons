#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"

export LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$CONFIG_PATH")
export TZ=$(jq -r '.tz // "UTC"' "$CONFIG_PATH")

echo "[abs-kosync-bridge] Starting (LOG_LEVEL=$LOG_LEVEL, TZ=$TZ)"

exec /app/start.sh
