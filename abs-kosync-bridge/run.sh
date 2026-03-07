#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"

export LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$CONFIG_PATH")
export TZ=$(jq -r '.tz // "UTC"' "$CONFIG_PATH")
BOOKS_PATH=$(jq -r '.books_path // "/media/books"' "$CONFIG_PATH")

# /books is hardcoded in the app — symlink the user's media path
if [ "$BOOKS_PATH" != "/books" ]; then
    rm -rf /books
    ln -sf "$BOOKS_PATH" /books
fi

echo "[abs-kosync-bridge] Books: /books -> $BOOKS_PATH"
echo "[abs-kosync-bridge] Starting (LOG_LEVEL=$LOG_LEVEL, TZ=$TZ)"

exec /app/start.sh
