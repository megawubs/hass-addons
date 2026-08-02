# OPDS Proxy

## Configuration

```yaml
log_level: info
feeds:
  - name: "Audiobookshelf"
    url: "http://e419b1cb-abs-opds:3010"
    username: "bram"
    password: "hunter2"
    local_only: true
```

### Option: `feeds`

The catalogs shown on the home page. At least one is required — the add-on
refuses to start without one, because opds-proxy has nothing to proxy.

| Field | Required | Description |
| ----- | -------- | ----------- |
| `name` | yes | Label shown on the home page. |
| `url` | yes | Full URL of the OPDS feed, including `http://` or `https://`. |
| `username` | no | Username for feeds behind HTTP basic authentication. |
| `password` | no | Password that goes with `username`. |
| `local_only` | no | See [Stored credentials](#stored-credentials). Defaults to `false`. |

Leave `username` and `password` empty to be prompted in the browser instead.
Credentials entered that way are stored in a signed cookie on the device, so
each eReader logs in once.

### Option: `log_level`

One of `trace`, `debug`, `info`, `notice`, `warning`, `error` or `fatal`.
Defaults to `info`. `debug` and `trace` also switch opds-proxy itself into
debug mode, which logs every request it makes.

## Pointing at another add-on

Add-ons reach each other over Home Assistant's internal network using the
hostname `{repository}_{slug}`, with underscores replaced by hyphens. For
add-ons from this repository the repository part is `e419b1cb`, so the
[AudiobookShelf OPDS Server](../abs-opds) add-on is reachable at:

```text
http://e419b1cb-abs-opds:3010
```

Note the **internal** port `3010`, not whatever host port you mapped it to.

That hostname is a hash of the URL you used when adding this repository to
Home Assistant. If the default does not resolve, look up the real one under
**Settings → Add-ons → \<the other add-on\> → Info**, where the hostname is
listed, and use that instead. Using the IP address of your Home Assistant host
together with the *host* port works too, and does not depend on the hash.

## Using it from an eReader

Open `http://<your-home-assistant-ip>:8080` in the eReader's browser.

Downloads are converted based on the device's user agent:

- **Kobo** — EPUB files are converted to KEPUB, which enables Kobo's native
  reading statistics and page turn handling.
- **Everything else** — the file is passed through unchanged.

MOBI conversion for older Kindles is *not* available in this add-on. Upstream
relies on Amazon's discontinued `kindlegen`, which only exists as a 32-bit
glibc binary and cannot run on the Alpine-based Home Assistant base image.
Kindles receive the original EPUB, which current firmware handles natively.

## Networking and ingress

This add-on is exposed on a port rather than through Home Assistant ingress.
That is deliberate: opds-proxy generates absolute links (`/feed`, `/static/…`),
so it cannot be served from the ingress sub-path. Serving it directly also
means eReaders reach it without going through Home Assistant authentication,
which most eReader browsers cannot complete anyway.

The default host port is `8080`. Change it under **Configuration → Network** if
something else on your machine already uses it.

## Security

### Stored credentials

Credentials in `feeds` are sent by the proxy on your behalf, so anyone who can
reach the proxy can read that library without logging in. Set `local_only: true`
to only use the stored credentials for requests coming from a private or
loopback address; requests from outside get the login form instead.

Only expose this add-on to the internet behind a reverse proxy with TLS, and
keep `local_only: true` on any feed with stored credentials.

### Sessions

Cookie signing keys are generated on first start and kept in `/data`, so
sessions survive add-on restarts and updates. Delete the add-on's data to
invalidate every session.

## Advanced: bring your own config file

For feed setups the options above cannot express, drop a `config.yml` in the
add-on configuration folder:

```text
/addon_configs/e419b1cb_opds-proxy/config.yml
```

When that file exists it is used verbatim and all options except `log_level`
are ignored. You are then responsible for `port` (which must stay `8080`) and
for the `auth.hash_key` / `auth.block_key` pair. See the [upstream
documentation][upstream-config] for the full schema.

## Troubleshooting

**"No feeds configured"** — the `feeds` list is empty. Add one and restart.

**"Every feed needs both a name and a url"** — one of the entries is missing a
field. The message lists which entry, counting from 1.

**A feed shows a connection error** — check the `url` from the add-on's own
perspective. `localhost` refers to the add-on container itself, not to Home
Assistant or to another add-on. See [Pointing at another add-on](#pointing-at-another-add-on).

**Downloads fail on a Kobo** — set `log_level` to `debug` and retry; the log
will show whether the `kepubify` conversion or the upstream download failed.

[upstream-config]: https://github.com/evan-buss/opds-proxy#configuration
