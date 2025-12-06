#!/bin/bash
set -e

echo "[koreader-sync-server] Starting KOReader Sync Server..."

# Setup persistent storage directories
REDIS_DATA_DIR="/addon_config/redis"
REDIS_LOG_DIR="/addon_config/logs/redis"
APP_LOG_DIR="/addon_config/logs/app"

mkdir -p "$REDIS_DATA_DIR"
mkdir -p "$REDIS_LOG_DIR"
mkdir -p "$APP_LOG_DIR"

echo "[koreader-sync-server] Setting up persistent storage..."

# Symlink Redis data directory
if [ ! -L "/var/lib/redis" ]; then
    rm -rf /var/lib/redis
    ln -sf "$REDIS_DATA_DIR" /var/lib/redis
    echo "[koreader-sync-server] Created symlink: /var/lib/redis -> $REDIS_DATA_DIR"
fi

# Symlink Redis logs
if [ ! -L "/var/log/redis" ]; then
    rm -rf /var/log/redis
    ln -sf "$REDIS_LOG_DIR" /var/log/redis
    echo "[koreader-sync-server] Created symlink: /var/log/redis -> $REDIS_LOG_DIR"
fi

# Symlink application logs
if [ ! -L "/app/koreader-sync-server/logs" ]; then
    rm -rf /app/koreader-sync-server/logs
    ln -sf "$APP_LOG_DIR" /app/koreader-sync-server/logs
    echo "[koreader-sync-server] Created symlink: /app/koreader-sync-server/logs -> $APP_LOG_DIR"
fi

# Ensure proper permissions
chown -R redis:redis "$REDIS_DATA_DIR" "$REDIS_LOG_DIR" 2>/dev/null || true

echo "[koreader-sync-server] Persistent storage configured"
echo "[koreader-sync-server]   Redis data: $REDIS_DATA_DIR"
echo "[koreader-sync-server]   Redis logs: $REDIS_LOG_DIR"
echo "[koreader-sync-server]   App logs: $APP_LOG_DIR"
echo "[koreader-sync-server] Starting server..."

# Start the sync server (using the default command from the base image)
exec /usr/local/bin/koreader-sync-server
