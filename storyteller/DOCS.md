# Home Assistant add-on: Storyteller

[Storyteller](https://gitlab.com/storyteller-platform/storyteller) takes an
ebook and an audiobook you already own and lines them up, so you can switch
between reading and listening without losing your place. This add-on runs the
Storyteller server; you read the results in the Storyteller mobile apps, in any
EPUB 3 Media Overlay reader, or in the built-in web reader.

## Installation

1. Install the add-on and start it. The first start takes a while: the add-on is
   built on your device on top of the upstream image, which is large.
2. Open the web interface on port 8001 and create your admin account.
3. Point the mobile apps at the same address.

Nothing needs to be configured first — the add-on generates the instance secret
key for you on the first start.

## Configuration

| Option | Default | What it does |
| --- | --- | --- |
| `log_level` | `info` | Detail level of the add-on log (`error`, `warn`, `info`, `debug`, `trace`). |
| `enable_web_reader` | `false` | Enables Storyteller's in-browser reader. Upstream still calls it experimental. |
| `secret_key` | generated | The key that signs your login tokens. See below. |
| `auth_url` | unset | Only needed for OAuth/OIDC logins: the full external URL of your instance, e.g. `https://storyteller.example.com`. |

Everything else — library name, transcription engine, SMTP, users — is
configured in Storyteller's own settings page, not here.

### The secret key

Storyteller refuses to start without a secret key, so the add-on writes a random
one to `/data/secret_key` the first time it starts and reuses it afterwards.
That file is part of the add-on's backup.

Fill in the `secret_key` option only when you want to reuse the key from an
existing Storyteller instance, for example when moving over from Docker Compose
and wanting existing logins to keep working. Clearing the option again keeps the
last key that was set; it does not go back to a generated one.

### Advanced settings

Storyteller can also be configured
[declaratively](https://storyteller-platform.gitlab.io/storyteller/docs/installation/self-hosting)
with a JSON file. Drop one at `storyteller/storyteller.json` in your Home
Assistant `addon_configs` folder and the add-on picks it up. Settings in that
file override the ones in Storyteller's UI and can no longer be changed there.

## Storage

The library, the database and the uploaded and aligned book files all live in
the add-on's own `/data` volume, so they are included in Home Assistant backups
and survive add-on updates. `/media` and `/share` are mounted as well, which is
useful if you want Storyteller to auto-import from a folder you already fill
from elsewhere.

## Requirements

Aligning books is heavy work: upstream asks for at least 4 GB of RAM and warns
that transcription on a low-power machine takes hours per book. A Raspberry Pi
will run the server fine, but expect alignment to be slow. Only `amd64` and
`aarch64` are supported, because those are the only images upstream publishes.

## Upgrading from `web-v1.4.0-ctc.6`

Versions of this add-on before 2.14.20 pinned `web-v1.4.0-ctc.6`, an
experimental build off a side branch that predates the 2.x line. The add-on's
own version is plain semver from now on — Home Assistant cannot parse or compare
version strings that are not bare numbers — while the upstream tag it
corresponds to is pinned in the Dockerfile. The jump is large, so:

- **Take a backup of the add-on before you update.** Storyteller migrates its
  database on startup, and there is no way back down.
- **Everyone has to sign in again.** The old build fell back to a hard-coded,
  publicly known signing key when no secret key was configured, which is exactly
  what the add-on now replaces with a generated one. Tokens issued under the old
  key are no longer valid — and were never really private to begin with.
- **Update the mobile apps too.** The 2.x server and the old apps do not talk to
  each other.
