# AudiobookShelf KOReader Sync Bridge

Synchronizes reading progress between AudiobookShelf, KOReader, Storyteller, and Booklore via a web UI dashboard.

## About

This addon wraps the [abs-kosync-bridge](https://github.com/cporcellijr/abs-kosync-bridge) project by cporcellijr.
It provides a web UI at port 5757 for configuring all integrations, with SQLite-backed state and Alembic migrations for reliability.

## Features

* 4-way sync: AudiobookShelf, KOReader, Storyteller, and Booklore
* Web UI dashboard for all configuration — no credential env vars needed
* Persistent SQLite state across restarts
* Active development with regular releases

## Setup

1. Start the addon
2. Navigate to the web UI at `http://[ha-ip]:5757`
3. Configure your integrations (ABS, KOReader, Storyteller, Booklore) via Settings
4. The bridge will start syncing automatically

## Configuration

All integration credentials are configured via the web UI. The addon options only cover:

* **books_path** (default: `/media/books`): Path to your ebook/audiobook files
* **log_level** (default: `INFO`): Logging verbosity (`DEBUG`, `INFO`, `WARNING`, `ERROR`)
* **tz** (default: `UTC`): Timezone (e.g. `Europe/Amsterdam`)

## Storage

* **Books**: Configured via `books_path` — symlinked to `/books` inside the container
* **App data**: Stored in `/data` (SQLite database, config) — persists across restarts

## Troubleshooting

* **Web UI not loading**: Check the addon logs for startup errors; Alembic migrations run on first start
* **Books not found**: Ensure `books_path` points to the correct location and the addon has read access
* **Sync not working**: Check the integration settings in the web UI at port 5757
