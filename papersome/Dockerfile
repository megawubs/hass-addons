# Stage 1: Clone source
FROM alpine/git AS source
RUN git clone --depth=1 https://github.com/thijskuilman/papersome /app

# Stage 2: Install Composer dependencies (needed by frontend build for Filament CSS)
FROM composer:2 AS vendor
WORKDIR /app
COPY --from=source /app/composer.json /app/composer.lock ./
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-scripts \
    --ignore-platform-reqs
COPY --from=source /app .
RUN composer dump-autoload --optimize --no-scripts 2>/dev/null || true

# Stage 3: Build frontend assets (requires vendor/ for Filament theme CSS resolution)
FROM node:20-alpine AS frontend
WORKDIR /app
COPY --from=source /app/package*.json ./
RUN npm ci
COPY --from=source /app .
COPY --from=vendor /app/vendor /app/vendor
RUN npm run build

# Stage 4: Final image
FROM serversideup/php:8.4-frankenphp

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    redis-server \
    chromium \
    nodejs \
    npm \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Puppeteer (skip built-in Chromium — we use system Chromium)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g puppeteer --unsafe-perm

# Copy application from build stages
COPY --from=source /app /var/www/html
COPY --from=vendor /app/vendor /var/www/html/vendor
COPY --from=frontend /app/public/build /var/www/html/public/build

# Copy s6-overlay services and init script
COPY rootfs/ /

# Make service scripts executable
RUN find /etc/s6-overlay/s6-rc.d -type f \( -name "run" -o -name "up" \) -exec chmod +x {} \; && \
    chmod +x /usr/local/bin/papersome-init.sh

# Fix application ownership
RUN chown -R www-data:www-data /var/www/html

ENV APP_ENV=production \
    APP_DEBUG=false \
    DB_CONNECTION=mysql \
    DB_HOST=127.0.0.1 \
    DB_PORT=3306 \
    DB_DATABASE=papersome \
    DB_USERNAME=papersome \
    CACHE_STORE=redis \
    REDIS_HOST=127.0.0.1 \
    REDIS_PORT=6379 \
    REDIS_CLIENT=phpredis \
    QUEUE_CONNECTION=redis \
    AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_MIGRATION=true \
    AUTORUN_LARAVEL_MIGRATION_FORCE=true \
    PHP_UPLOAD_MAX_FILE_SIZE=500M \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    BROWSERSHOT_CHROMIUM_PATH=/usr/bin/chromium \
    SERVER_NAME=:8088
