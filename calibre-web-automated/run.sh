#!/usr/bin/with-contenv bashio

# Read config option
CALIBRE_LIBRARY_PATH=$(bashio::config 'calibre_library_path')

# Create symlink from CWA's expected path to user's library path
bashio::log.info "Creating symlink: /calibre-library -> ${CALIBRE_LIBRARY_PATH}"
ln -sf "${CALIBRE_LIBRARY_PATH}" /calibre-library

# Export environment variables
export TZ=$(bashio::config 'timezone')
export NETWORK_SHARE_MODE=$(bashio::config 'network_share_mode')

# Export Hardcover token if provided
if bashio::config.has_value 'hardcover_token'; then
    export HARDCOVER_TOKEN=$(bashio::config 'hardcover_token')
fi

# Start CWA
bashio::log.info "Starting Calibre-Web-Automated..."
exec /init
