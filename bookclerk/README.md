# Bookclerk

Multi-storefront audiobook library manager: Audible, Libro.fm, Chirp and
GraphicAudio in one library, with a web UI.

## About

This add-on builds and runs [bookclerk](https://github.com/fritz-fritz/bookclerk),
a Rust daemon (`bookclerkd`) that syncs your purchased audiobooks from
multiple stores into one local library and downloads them DRM-free. Unlike
most add-ons in this repository, bookclerk has no published upstream Docker
image — this add-on compiles it from source at a pinned commit and is built
by CI (see `image:` in `config.yaml`), not by the Supervisor on your device.

## Multiple accounts per store

Bookclerk stores credentials per account, not one-per-source, so you can add
**more than one GraphicAudio or Audible account**:

- `graphicaudio_accounts`, `libro_fm_accounts`, `chirp_accounts` each take a
  list of `{email, password}` entries — add as many as you own.
- `audible_marketplaces` takes a list of marketplace codes (e.g. `us`, `uk`)
  — see below, Audible cannot be logged in automatically.

## Audible needs a manual, one-time login

Audible authenticates via Amazon's interactive OAuth flow
(`bookclerk auth login -m <marketplace>`), which cannot be scripted from
`run.sh`. If you list any `audible_marketplaces`, the add-on log will print
the exact command to run, once per Audible account you own. Open a terminal
into the add-on (Settings → Add-ons → Bookclerk → Terminal, or `docker exec`)
and run it there. Libro.fm, Chirp and GraphicAudio use plain email/password
and log in automatically on every start.

## Configuration

- **auth_password** (required): protects the operator HTTP API (bound to
  `0.0.0.0:8787` here so the web UI is reachable) and encrypts stored source
  credentials at rest.
- **auto_acquire**: enable scheduled automatic downloads. Leave `false`
  until you've confirmed logins and a manual sync work as expected.
- **output_path**: subfolder under Home Assistant's shared `/media`, e.g.
  `Audiobooks` → files land in `/media/Audiobooks`.
- **log_level**: a `tracing`-style filter, e.g. `info`, `debug`,
  `bookclerkd=debug,warn`.
- **plugin_isolation**: `required` | `best-effort` | `off`. Bookclerk
  normally runs each store's plugin in a self-confined subprocess
  (`bookclerk-jail`). Defaults to `best-effort` here because the jail's
  namespacing may not have the privileges it wants inside the Supervisor's
  own container; `required` will refuse to load plugins if confinement
  fails, `off` skips it. This add-on does not request `privileged:` — if you
  want to try `required`, you'll need to add `privileged: [SYS_ADMIN]` and
  `apparmor: false` to `config.yaml` yourself.
- **graphicaudio_access**: `web` (default), `zip`, or `device` — see
  bookclerk's own [`docs/sources.md`](https://github.com/fritz-fritz/bookclerk/blob/main/docs/sources.md)
  for the tradeoffs.
- **audiobookshelf_host** / **audiobookshelf_api_key**: optional. Point these
  at an existing Audiobookshelf instance (e.g. the `audiobookshelf` add-on in
  this same repository) to enable bookclerk's Audiobookshelf integration:
  notifying ABS to rescan on new acquisitions, optional listening sync, and
  optional user watch. The add-on's own container hostname (e.g.
  `app_<repo-hash>_audiobookshelf`) is not predictable across installs and
  its bare slug (`audiobookshelf`) does not resolve — use
  `http://homeassistant:13378` instead (Home Assistant's own hostname
  routes through the Supervisor's Docker network gateway to any add-on's
  published host port; substitute Audiobookshelf's actual port if you
  changed it). Leave `audiobookshelf_host` empty to skip this entirely —
  it's off by default. An API key is required for the integration to do
  anything; generate one in Audiobookshelf under
  Settings → Users.

## Web UI and the operator token

The web UI at `http://homeassistant.local:8787` needs bookclerk's operator
token to sign in. It's generated on first start at `/data/operator.token`.
Open a terminal into the add-on and run:

```
cat /data/operator.token
```

### Checking your accounts as operator

The web UI's "Accounts" page is a **portal** (multi-user linking) feature —
signed in as operator, it will always show an empty list or a "requires a
portal session" error, even when your storefront accounts are configured and
working correctly. This is expected, not a bug. To check account status,
use the CLI instead:

```
docker ps --format '{{.Names}}' | grep bookclerk   # find the container name — app_<repo-hash>_bookclerk
docker exec -e BOOKCLERK_AUTH_PASSWORD='<your auth_password option>' \
  <container name from above> bookclerk auth list
```

(`docker exec` doesn't inherit `run.sh`'s exported environment, so
`BOOKCLERK_AUTH_PASSWORD` has to be passed explicitly.)

## First run

`/data/config.toml` is generated once on first start (sources enabled based
on which account lists you filled in) and is yours to hand-edit afterwards —
the add-on never overwrites an existing `config.toml`.

## Known limitations

- No upstream Docker image exists yet, so this add-on tracks a pinned commit
  SHA rather than a tagged release (see the top of `Dockerfile`). Bumping it
  is a manual step, not an automated cron job like some other add-ons here.
- First-party store plugins are staged into the image with bookclerk's own
  `cargo stage-plugins` tooling. This is newer, less-traveled code than the
  wrapped add-ons in this repo — check the add-on log carefully on first
  install.
- ML-based recommendation embeddings are disabled
  (`BOOKCLERK_DISCOVERY_EMBEDDINGS_ENABLED=false`). bookclerk's ONNX embedder
  downloads/loads a MiniLM model synchronously inside the `/api/discover/
  recommendations` handler (the Discover tab is the default post-login view)
  with no `spawn_blocking` and no visible timeout — reproduced this hanging
  the entire daemon indefinitely, confirmed via an orphaned
  huggingface-hub `.lock` file left next to a fully-downloaded model blob.
  Recommendations still work via a lightweight local-hash embedder instead
  of the ONNX one.

## Support

For issues with this add-on's packaging, open an issue in this repository.
For issues with bookclerk itself, use
https://github.com/fritz-fritz/bookclerk/issues.

## Credits

This add-on packages [bookclerk](https://github.com/fritz-fritz/bookclerk) by
fritz-fritz.
