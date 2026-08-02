# OPDS Proxy

Puts a plain, mobile-friendly web interface in front of your OPDS catalogs, so
you can browse and download books straight from the browser on your Kobo,
Kindle or any other eReader — no dedicated OPDS app required.

This add-on packages [opds-proxy][upstream] by Evan Buss.

## Why you might want this

OPDS feeds are XML. Most eReader browsers cannot render them, and the OPDS apps
that can often choke on HTTP basic authentication. OPDS Proxy sits in between:
it renders the feed as a simple HTML page, handles the authentication for you,
and converts EPUB downloads to KEPUB on the fly for Kobo devices.

It is a *client* for OPDS feeds, not a library server. Point it at a catalog you
already run — for example the [AudiobookShelf OPDS Server](../abs-opds) add-on
in this repository, Calibre-Web, or a public catalog such as Project Gutenberg.

## Installation

1. Install the add-on from this repository.
2. Set at least one feed under **Configuration** (see [DOCS.md](DOCS.md)).
3. Start the add-on and open the web UI.
4. On your eReader, browse to `http://<your-home-assistant-ip>:8080`.

Full configuration reference and troubleshooting: [DOCS.md](DOCS.md).

[upstream]: https://github.com/evan-buss/opds-proxy
