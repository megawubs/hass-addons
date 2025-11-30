# AudiobookShelf KOReader Sync Bridge

This Home Assistant addon synchronizes reading progress between AudiobookShelf audiobooks and KOReader ebooks using AI transcription and semantic text matching.

## About

This addon wraps the [abs-kosync-bridge](https://github.com/J-Lich/abs-kosync-bridge) project by J-Lich, which uses OpenAI's Faster-Whisper to transcribe audiobooks and match them to ebook text for accurate position syncing.

## How It Works

1. Downloads and transcribes your audiobooks from AudiobookShelf
2. Matches spoken text to your ebook content using semantic analysis
3. Syncs your position between AudiobookShelf (audiobook) and KOReader (ebook)
4. Works bidirectionally - progress updates in either direction

## Prerequisites

You need:
- **AudiobookShelf** with audiobooks
- **KOReader Sync Server** (kosync) - use the koreader-sync-server addon
- **Matching books** in both AudiobookShelf (audiobook) and KOReader (ebook)

## Configuration

### Required Settings

- **abs_server**: URL to your AudiobookShelf instance (e.g., `http://audiobookshelf:13378`)
- **abs_key**: AudiobookShelf API key (get from Settings → Users → Your User → API Token)
- **kosync_server**: URL to your KOReader Sync Server (default: `http://homeassistant:7200`)
- **kosync_user**: Your KOReader sync username
- **kosync_key**: Your KOReader sync password

### Optional Settings

- **sync_period_mins** (default: `5`): How often to check for sync updates in minutes
- **fuzzy_match_threshold** (default: `80`): Confidence score for matching text (0-100)
- **sync_delta_abs_seconds** (default: `30`): Ignore AudiobookShelf changes smaller than this
- **sync_delta_kosync_percent** (default: `1`): Ignore KOReader changes smaller than this percentage
- **log_level** (default: `INFO`): Logging verbosity (DEBUG, INFO, WARNING, ERROR)

## Usage

1. Configure the addon with your AudiobookShelf and KOReader sync server details
2. Start the addon
3. The bridge will automatically sync progress between matching books
4. Monitor the logs to see sync activity

## Notes

- **AI Processing**: The addon uses AI transcription which requires computational resources
- **First Run**: Initial transcription of audiobooks may take time
- **Matching**: Books must have similar content to sync properly
- **Network**: Ensure the addon can reach both AudiobookShelf and KOReader sync server

## Troubleshooting

- **No sync happening**: Check that book titles match between AudiobookShelf and KOReader
- **Wrong positions**: Adjust `fuzzy_match_threshold` (higher = stricter matching)
- **Too many syncs**: Increase `sync_delta_abs_seconds` or `sync_delta_kosync_percent`
- **High resource usage**: This is normal during transcription - the addon is optimized for low-resource environments
