# Libro.fm Audiobook Downloader

Automatically syncs and downloads your audiobook library from Libro.fm to Home Assistant.

## About

This addon runs the [librofm-downloader](https://github.com/burntcookie90/librofm-downloader) application, which checks Libro.fm daily (or at your configured interval) for new audiobooks and downloads them to your media directory.

## Features

- Automatic audiobook synchronization on a schedule
- Multiple format options: MP3, M4B with MP3 fallback, or M4B with conversion
- Chapter renaming using Libro.fm metadata
- ID3 tag writing for better player compatibility
- Web UI for manual syncing and status monitoring
- Customizable folder organization patterns
- Optional Hardcover book tracker integration
- Healthchecks.io monitoring support

## Installation

1. Add this repository to your Home Assistant Supervisor
2. Install the "Librofm downloader" addon
3. Configure your Libro.fm credentials in the addon configuration
4. Start the addon

## Configuration

### Required Settings

- **libro_fm_username**: Your Libro.fm account email
- **libro_fm_password**: Your Libro.fm account password

### Format Options

- **format**: Download format (default: `M4B_MP3_FALLBACK`)
  - `MP3`: Download as individual MP3 files
  - `M4B_MP3_FALLBACK`: Prefer M4B, fall back to MP3 if unavailable
  - `M4B_CONVERT_FALLBACK`: Try M4B, convert MP3 to M4B if needed

### Sync Settings

- **sync_interval**: How often to check for new books
  - `h`: Hourly
  - `d`: Daily (default)
  - `w`: Weekly

- **parallel_count**: Number of books to download simultaneously (1-10, default: 1)

### Organization

- **path_pattern**: Customize folder structure (default: `FIRST_AUTHOR/BOOK_TITLE`)
  - Available tokens:
    - `FIRST_AUTHOR`: First listed author name
    - `ALL_AUTHORS`: All authors (comma-separated)
    - `SERIES_NAME`: Book series name
    - `BOOK_TITLE`: Title of the book
    - `ISBN`: ISBN number
    - `FIRST_NARRATOR`: First listed narrator
    - `ALL_NARRATORS`: All narrators (comma-separated)
    - `PUBLICATION_YEAR`: Year published
    - `PUBLICATION_MONTH`: Month published
    - `PUBLICATION_DAY`: Day published
  - Examples:
    - `SERIES_NAME/BOOK_TITLE`
    - `FIRST_AUTHOR/PUBLICATION_YEAR/BOOK_TITLE`
    - `FIRST_NARRATOR/SERIES_NAME/BOOK_TITLE`

- **rename_chapters**: Rename chapter files from "Track - #.mp3" to include chapter titles (default: false)
- **write_title_tag**: Write ID3 title tags (requires rename_chapters enabled, default: false)

### Logging

- **log_level**: Logging verbosity
  - `NONE`: No logging
  - `INFO`: Standard logging (default)
  - `VERBOSE`: Detailed logging

### Advanced Options

- **hardcover_token**: Optional Hardcover.app API token for book tracking integration
- **hardcover_sync_mode**: How to sync with Hardcover (if token provided)
  - `LIBRO_WISHLISTS_TO_HARDCOVER`: Sync wishlists to Hardcover
  - `LIBRO_OWNED_TO_HARDCOVER`: Sync owned books to Hardcover (default)
  - `LIBRO_ALL_TO_HARDCOVER`: Sync everything to Hardcover
  - `HARDCOVER_WANT_TO_READ_TO_LIBRO`: Sync Hardcover want-to-read to Libro
  - `ALL`: Bidirectional sync
- **skip_tracking_isbns**: Comma-separated ISBNs to exclude from Hardcover tracking
- **healthcheck_id**: Optional healthchecks.io UUID for monitoring

## Usage

### Web Interface

Access the web UI at `http://homeassistant.local:8080` (or your Home Assistant IP:8080).

The web interface allows you to:
- View current configuration
- Manually trigger a sync
- Force re-download entire library with the overwrite option

### Download Location

Downloaded audiobooks are saved to Home Assistant's `/media` directory using your `path_pattern` for organization.

**Example**: With default settings:
- `path_pattern`: `FIRST_AUTHOR/BOOK_TITLE`
- Books save to: `/media/Andy Weir/Project Hail Mary/`

**Custom Example**:
- Set `path_pattern` to `Audiobooks/SERIES_NAME/BOOK_TITLE`
- Books save to: `/media/Audiobooks/The Expanse/Leviathan Wakes/`

**Network Mounts**: If you have network storage mounted in Home Assistant's `/media` directory, books will download there automatically.

### First Run

On the first run with a new account:
1. The addon will scan your entire Libro.fm library
2. Download all audiobooks based on your format setting
3. This may take several hours depending on library size
4. Subsequent runs only download new books

## Troubleshooting

### Addon not showing up
- Check that all files are properly formatted
- Verify the slug matches the directory name
- Restart Home Assistant Supervisor

### Books not downloading
- Check credentials in the addon logs
- Verify Libro.fm account is active
- Check available disk space in Home Assistant

### Wrong download location
- Review your `path_pattern` configuration
- Check the addon logs for the actual download path
- Ensure `/media` is properly mounted

### Web UI not accessible
- Verify port 8080 is not blocked by firewall
- Check addon is running
- Try accessing via `http://homeassistant.local:8080`

## Support

For issues with the addon configuration, create an issue in this repository.

For issues with the librofm-downloader application itself, report them at https://github.com/burntcookie90/librofm-downloader/issues

## Credits

This addon wraps the excellent [librofm-downloader](https://github.com/burntcookie90/librofm-downloader) by burntcookie90.
