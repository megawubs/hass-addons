# AudiobookShelf KOReader Sync Bridge

Synchronizes reading progress between AudiobookShelf, KOReader, Storyteller, and Booklore via a web UI dashboard.

## About

This addon wraps the [abs-kosync-bridge](https://github.com/cporcellijr/abs-kosync-bridge) project by cporcellijr.
It provides a web UI at port 5757 for configuring all integrations and system paths, with SQLite-backed state and Alembic migrations for reliability.

## Features

* 4-way sync: AudiobookShelf, KOReader, Storyteller, and Booklore
* Web UI dashboard for all configuration — no credential env vars needed
* System paths (books, audiobooks, storyteller library) configurable via the UI
* Persistent SQLite state across restarts
* Active development with regular releases

## Setup

1. Start the addon
2. Navigate to the web UI at `http://[ha-ip]:5757`
3. Go to **Settings → System Paths** and set your paths (e.g. Books Directory: `/media/books`)
4. Configure your integrations (ABS, KOReader, Storyteller, Booklore) via Settings
5. The bridge will start syncing automatically

## Configuration

All integration credentials and system paths are configured via the web UI. The addon options only cover:

* **log_level** (default: `INFO`): Logging verbosity (`DEBUG`, `INFO`, `WARNING`, `ERROR`)
* **tz** (default: `UTC`): Timezone (e.g. `Europe/Amsterdam`)

HA directories available inside the container:

* `/media` — Home Assistant media directory
* `/share` — Home Assistant share directory
* `/addon_config` — Addon config directory

## Storage

* **App data**: Stored in `/data` (SQLite database, config) — persists across restarts

## Troubleshooting

* **Web UI not loading**: Check the addon logs for startup errors; Alembic migrations run on first start
* **Books not found**: Set the correct path under Settings → System Paths in the web UI
* **Sync not working**: Check the integration settings in the web UI at port 5757
