#!/bin/bash
set -e

echo "[papersome-init] Starting initialization..."

# Read configuration from Home Assistant
APP_URL_OPTION=$(jq -r '.app_url // ""' /data/options.json)
DB_PASSWORD=$(jq -r '.db_password // "papersome"' /data/options.json)

# Ensure addon_config directories exist
mkdir -p /addon_config/mariadb /addon_config/redis /addon_config/storage

# Wait for MariaDB to accept connections
echo "[papersome-init] Waiting for MariaDB..."
until mysqladmin -h 127.0.0.1 -P 3306 -u root ping --silent 2>/dev/null; do
    sleep 2
done
echo "[papersome-init] MariaDB is ready"

# Wait for Redis
echo "[papersome-init] Waiting for Redis..."
until redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q "PONG"; do
    sleep 1
done
echo "[papersome-init] Redis is ready"

# Generate APP_KEY if not stored yet
APP_KEY_FILE="/addon_config/.app_key"
if [ ! -f "$APP_KEY_FILE" ]; then
    echo "[papersome-init] Generating APP_KEY..."
    # Use openssl to generate a base64-encoded 32-byte key
    APP_KEY="base64:$(openssl rand -base64 32)"
    echo "$APP_KEY" > "$APP_KEY_FILE"
    echo "[papersome-init] APP_KEY generated and saved"
else
    APP_KEY=$(cat "$APP_KEY_FILE")
    echo "[papersome-init] Using existing APP_KEY"
fi

# Determine APP_URL
if [ -n "$APP_URL_OPTION" ]; then
    APP_URL="$APP_URL_OPTION"
else
    HOST_IP=$(hostname -i | awk '{print $1}')
    APP_URL="http://${HOST_IP}:8088"
fi
echo "[papersome-init] APP_URL: $APP_URL"

# Write .env file
cat > /var/www/html/.env <<EOF
APP_NAME=Papersome
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_URL=${APP_URL}

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=papersome
DB_USERNAME=papersome
DB_PASSWORD=${DB_PASSWORD}

CACHE_STORE=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_CLIENT=phpredis

QUEUE_CONNECTION=redis

LOG_CHANNEL=stderr
LOG_LEVEL=debug

PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
BROWSERSHOT_CHROMIUM_PATH=/usr/bin/chromium
BROWSERSHOT_NO_SANDBOX=true
EOF
echo "[papersome-init] .env file written"

# Set up MariaDB database and user
echo "[papersome-init] Setting up MariaDB database..."
mysql -h 127.0.0.1 -u root -e "
  CREATE DATABASE IF NOT EXISTS papersome CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS 'papersome'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON papersome.* TO 'papersome'@'127.0.0.1';
  FLUSH PRIVILEGES;
" 2>/dev/null && echo "[papersome-init] Database user configured" || echo "[papersome-init] Database user may already exist, continuing"

# Set up persistent storage directory
mkdir -p /addon_config/storage/{app,framework/{cache,sessions,views},logs}
mkdir -p /addon_config/storage/app/public

if [ ! -f "/addon_config/storage/.initialized" ]; then
    echo "[papersome-init] Seeding storage directory..."
    if [ -d "/var/www/html/storage" ]; then
        cp -rn /var/www/html/storage/. /addon_config/storage/ 2>/dev/null || true
    fi
    touch /addon_config/storage/.initialized
fi

# Replace storage directory with symlink to addon_config
rm -rf /var/www/html/storage
ln -sf /addon_config/storage /var/www/html/storage
chown -R www-data:www-data /addon_config/storage 2>/dev/null || true

# Create public storage link
cd /var/www/html
php artisan storage:link --force 2>/dev/null || true

# Run database migrations
echo "[papersome-init] Running database migrations..."
php artisan migrate --force --no-interaction
echo "[papersome-init] Migrations complete"

echo "[papersome-init] Initialization complete"
