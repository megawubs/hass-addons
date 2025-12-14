#!/bin/bash

# Read configuration from Home Assistant
CONFIG_PATH="/data/options.json"

if [ -f "$CONFIG_PATH" ]; then
    echo "[librofm-downloader] Reading configuration from Home Assistant"

    # Get configuration values
    LIBRO_FM_USERNAME=$(jq -r '.libro_fm_username // ""' "$CONFIG_PATH")
    LIBRO_FM_PASSWORD=$(jq -r '.libro_fm_password // ""' "$CONFIG_PATH")
    FORMAT=$(jq -r '.format // "M4B_MP3_FALLBACK"' "$CONFIG_PATH")
    SYNC_INTERVAL=$(jq -r '.sync_interval // "d"' "$CONFIG_PATH")
    RENAME_CHAPTERS=$(jq -r '.rename_chapters // false' "$CONFIG_PATH")
    WRITE_TITLE_TAG=$(jq -r '.write_title_tag // false' "$CONFIG_PATH")
    PARALLEL_COUNT=$(jq -r '.parallel_count // 1' "$CONFIG_PATH")
    LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$CONFIG_PATH")
    PATH_PATTERN=$(jq -r '.path_pattern // "FIRST_AUTHOR/BOOK_TITLE"' "$CONFIG_PATH")
    HARDCOVER_TOKEN=$(jq -r '.hardcover_token // ""' "$CONFIG_PATH")
    HARDCOVER_SYNC_MODE=$(jq -r '.hardcover_sync_mode // "LIBRO_OWNED_TO_HARDCOVER"' "$CONFIG_PATH")
    SKIP_TRACKING_ISBNS=$(jq -r '.skip_tracking_isbns // ""' "$CONFIG_PATH")
    HEALTHCHECK_ID=$(jq -r '.healthcheck_id // ""' "$CONFIG_PATH")
    BOOKS_PATH=$(jq -r '.books_path // "/media"' "$CONFIG_PATH")

    # Export required environment variables
    export LIBRO_FM_USERNAME
    export LIBRO_FM_PASSWORD
    export FORMAT
    export SYNC_INTERVAL
    export PARALLEL_COUNT
    export LOG_LEVEL
    export PATH_PATTERN

    # Export boolean options
    export RENAME_CHAPTERS
    export WRITE_TITLE_TAG

    echo "[librofm-dowloader] Storage directories ready"
    echo "[librofm-dowloader]   Books: $BOOKS_PATH"
    # Export optional Hardcover integration if token provided
    if [ -n "$HARDCOVER_TOKEN" ]; then
        export HARDCOVER_TOKEN
        export HARDCOVER_SYNC_MODE
    fi

    # Export optional skip tracking ISBNs if provided
    if [ -n "$SKIP_TRACKING_ISBNS" ]; then
        export SKIP_TRACKING_ISBNS
    fi

    # Export optional healthcheck ID if provided
    if [ -n "$HEALTHCHECK_ID" ]; then
        export HEALTHCHECK_ID
    fi

    # Note: /data is already mounted by Home Assistant to /config
    # The app uses /data for persistent storage, which is perfect

    # Log configuration (without password)
    echo "[librofm-downloader] Configuration loaded successfully"
    echo "[librofm-downloader] Format: ${FORMAT}"
    echo "[librofm-downloader] Sync Interval: ${SYNC_INTERVAL}"
    echo "[librofm-downloader] Path Pattern: ${PATH_PATTERN}"
    echo "[librofm-downloader] Books will download to: /media/${PATH_PATTERN}"
else
    echo "[librofm-downloader] Warning: No config file found at $CONFIG_PATH"
fi

# Change to app directory and run the application
cd /app || exit 1
echo "[librofm-downloader] Starting Libro.fm downloader..."

exec bin/app --media-dir="$BOOKS_PATH"
