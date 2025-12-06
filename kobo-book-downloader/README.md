# Home Assistant Add-on: Kobo Book Downloader

Download DRM-free ebooks and audiobooks from your Kobo library.

## About

This add-on wraps [kobo-book-downloader](https://github.com/subdavis/kobo-book-downloader) to allow you to download and manage your Kobo purchases directly from Home Assistant. It removes DRM protection and downloads books in their original format.

## Features

- Web-based interface for managing downloads
- Automatic DRM removal
- Download ebooks in EPUB format
- Download audiobooks in their original format
- Persist downloads to Home Assistant's media folder

## Installation

1. Add this repository to your Home Assistant instance
2. Install the "Kobo Book Downloader" add-on
3. Configure the add-on (see Configuration section)
4. Start the add-on
5. Access the web UI to log in with your Kobo credentials

## Configuration

```yaml
download_path: /media/kobo-books
format_str: "{Title}"
log_level: info
```

### Option: `download_path`

The directory where downloaded books will be saved. This path should be within the `/media` directory to ensure persistence and accessibility.

Default: `/media/kobo-books`

### Option: `format_str`

The naming pattern for downloaded files. You can use metadata fields from your books to customize the filename.

Available fields:
- `{Title}` - Book title
- `{Author}` - Author name
- `{Series}` - Series name
- `{SeriesNumber}` - Series number

Examples:
- `{Title}` (default) - e.g., "The Great Gatsby.epub"
- `{Author}/{Title}` - e.g., "F. Scott Fitzgerald/The Great Gatsby.epub"
- `{Series}/{SeriesNumber} - {Title}` - e.g., "Harry Potter/1 - Harry Potter and the Philosopher's Stone.epub"

Default: `{Title}`

### Option: `log_level`

Controls the verbosity of log output.

Available options:
- `debug`
- `info` (default)
- `warning`
- `error`

## Usage

1. Open the web UI at `http://homeassistant.local:5000`
2. Log in with your Kobo account credentials
3. Browse your library and download books
4. Downloaded books will be saved to your configured download path

## Notes

- Your Kobo credentials are stored in `/config/kobodl.json`
- Downloaded books are saved in their original DRM-free format
- The web interface runs on port 5000

## Support

For issues specific to this add-on, please report them in this repository.

For issues with the underlying kobo-book-downloader tool, visit the [upstream repository](https://github.com/subdavis/kobo-book-downloader).
