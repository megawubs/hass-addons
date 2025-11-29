# AudiobookShelf OPDS Server

This Home Assistant addon provides an OPDS server for AudiobookShelf, allowing you to access your ebook and audiobook library from any OPDS-compatible reader like KOReader, Moon+ Reader, or Thorium.

## About

This addon wraps the [abs-opds](https://github.com/Vito0912/abs-opds) project by Vito0912, which creates an OPDS feed from your AudiobookShelf library.

## Configuration

### Required Settings

- **abs_url**: The URL to your AudiobookShelf instance (e.g., `http://audiobookshelf:13378` or `https://abs.example.com`)

### Optional Settings

- **show_audiobooks** (default: `false`): Include audiobooks in the OPDS feed
- **show_char_cards** (default: `false`): Show alphabetical character cards (A, B, C, etc.) for browsing
- **use_proxy** (default: `true`): Enable proxy for cover images (recommended for Docker deployments)
- **opds_page_size** (default: `20`): Number of items to display per page
- **opds_users** (default: `""`): Comma-separated list of users in format `username:ABS_API_TOKEN:password`
  - If left empty, users will authenticate directly with AudiobookShelf credentials
  - Example: `user1:token123:pass1,user2:token456:pass2`

## Usage

1. Configure the addon with your AudiobookShelf URL
2. Start the addon
3. Add the OPDS feed to your ereader: `http://homeassistant:3010`
4. Authenticate using either:
   - Your AudiobookShelf username and password (if `opds_users` is empty)
   - Custom credentials configured in `opds_users`

## Accessing from KOReader

1. Open KOReader on your device
2. Go to Search → OPDS Catalog
3. Add a new catalog:
   - Name: AudiobookShelf
   - URL: `http://homeassistant:3010`
   - Username: Your ABS username (or custom user from opds_users)
   - Password: Your ABS password (or custom password from opds_users)

## Notes

- The addon runs on port 3010 by default
- Make sure your AudiobookShelf instance is accessible from Home Assistant
- For external access, consider setting up a reverse proxy with proper SSL/TLS
