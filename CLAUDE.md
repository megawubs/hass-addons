# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

A Home Assistant add-on repository (`megawubs/hass-addons`) bundling **ten** add-ons. Each add-on lives in its own top-level directory whose name must equal the `slug` in its `config.yaml`. The bulk of the work here is *packaging* upstream projects as Home Assistant add-ons — there is very little original application code (the exceptions are `papersome`, which builds an upstream Laravel app from source, and `bookclerk`, which builds an upstream Rust workspace from source).

The add-ons:

| Directory | Wraps | How it ships |
|-----------|-------|--------------|
| `audiobookshelf` | advplyr/audiobookshelf | local build |
| `librofm-downloader` | burntcookie90/librofm-downloader | local build |
| `calibre-web-automated` | crocodilestick/Calibre-Web-Automated | local build |
| `kobo-book-downloader` | subdavis/kobo-book-downloader (`kobodl`) | local build |
| `koreader-sync-server` | koreader/kosync | local build |
| `abs-opds` | Vito0912/abs-opds | local build |
| `abs-kosync-bridge` | cporcellijr/abs-kosync-bridge | local build |
| `papersome` | thijskuilman/papersome (built from source) | **CI build → ghcr.io/megawubs** |
| `bookclerk` | fritz-fritz/bookclerk (built from source, pinned commit — no upstream image or tags exist) | **CI build → ghcr.io/megawubs** |
| `storyteller` | storyteller-platform/storyteller | **external image (GitLab registry), no build** |

## How an add-on is built — three distinct paths

This is the most important architectural distinction and it is driven entirely by the `image:` key in `config.yaml`:

1. **No `image:` key + a `Dockerfile`** → the Home Assistant Supervisor builds the image **locally on the user's device** at install time. This is the default for most add-ons here. CI does *not* build or publish these; the `builder` workflow explicitly skips them (`image == null`).
2. **`image:` pointing at `ghcr.io/megawubs/...` + a `Dockerfile`** → the GitHub Actions `builder` workflow builds and publishes to GHCR. `papersome` and `bookclerk` use this.
3. **`image:` pointing at an external registry + no `Dockerfile`** → the Supervisor pulls that image directly; nothing is built. Only `storyteller` uses this (GitLab registry).

Consequence: do **not** assume images land at `ghcr.io/megawubs/hass-addons/<slug>` — only `papersome` and `bookclerk` do. Most add-ons never produce a published image at all.

## The wrapped-add-on pattern

Eight of the ten add-ons follow the same recipe to adapt an upstream image to Home Assistant. When adding or fixing one, match this shape:

- **`Dockerfile`**: `FROM <upstream-image>`, then install `bash` + `jq` (`apk add` for Alpine bases, `apt-get install` for Debian/Ubuntu bases — check the base image), `COPY run.sh`, and override `CMD`/`ENTRYPOINT` to run `run.sh`.
- **`run.sh`**: reads Home Assistant's user config from `/data/options.json` using `jq -r '.key // "default"'`, then either exports the values as environment variables or passes them as CLI flags to the upstream process. **Always `exec` the upstream process last** so signals propagate.
- **`config.yaml`** `options:`/`schema:` must stay in sync with the keys `run.sh` reads from `/data/options.json`. A key read in `run.sh` but missing from `schema` (or vice-versa) is a common bug.

`papersome` and `bookclerk` are the outliers — both build an upstream app from source rather than wrapping a published image, and both are CI-built (see above) because a from-source build is too slow/heavy for the Supervisor to do on-device:

- `papersome`: multi-stage `Dockerfile` (clone → composer → npm build → FrankenPHP runtime) with bundled MariaDB + Redis + Chromium, orchestrated by **s6-overlay** services under `papersome/rootfs/etc/s6-overlay/`.
- `bookclerk`: multi-stage `Dockerfile` (clone a **pinned commit SHA** — no upstream tags/releases exist — → build the React UI → `cargo build --release` the daemon/CLI/helpers → `cargo stage-plugins --release` for the first-party store plugins → `debian:bookworm-slim` runtime). No s6-overlay; `rootfs/run.sh` plays the same role as a normal wrapped add-on's `run.sh`, just placed under `rootfs/` so it's covered by `MONITORED_FILES` (see Versioning below).

## Shared conventions across add-ons

- **Directory mappings** (`map:` in `config.yaml`): add-ons request `media:rw`, `share:rw`, and `addon_config:rw` as needed. Note the persistent-config path is **inconsistent** between add-ons: some `run.sh` scripts write to `/config`, others to `/addon_config` — verify the actual mount before trusting a path (this has caused real bugs).
- **Web UI**: exposed via the `ports:` + `webui:` keys. Each add-on uses a different host port.
- **Architectures** (`arch:`): all support `aarch64` + `amd64`; `audiobookshelf`, `calibre-web-automated`, `koreader-sync-server`, `librofm-downloader`, and `storyteller` additionally list `armv7`. The CI build matrix iterates `aarch64/amd64/armhf/armv7/i386` but filters by each add-on's `arch` list.

## Versioning & the update workflows

`version:` in each `config.yaml` tracks the **upstream** release, and bumping it is what triggers a rebuild (locally-built add-ons are rebuilt by the Supervisor when the version changes).

Five add-ons have a dedicated `.github/workflows/update-<addon>.yaml` cron job (daily) that queries the upstream GitHub tags/releases API and `sed`-bumps `version:` automatically: `audiobookshelf`, `calibre-web-automated`, `kobo-book-downloader`, `koreader-sync-server`, `librofm-downloader`. The other five (`abs-opds`, `abs-kosync-bridge`, `papersome`, `bookclerk`, `storyteller`) are bumped manually. `bookclerk` has no upstream tags to track anyway — bumping it means picking a new commit SHA and updating `BOOKCLERK_REF` in its `Dockerfile` as well as `version:`.

When making a change that must reach users, bump `version:` in `config.yaml` — editing only `run.sh` will **not** trigger a CI build (the `builder` workflow's `MONITORED_FILES` is `build.yaml config.yaml Dockerfile rootfs`), and for locally-built add-ons the Supervisor only rebuilds on a version change.

## CI workflows (`.github/workflows/`)

- **`builder.yaml`** — on push/PR to `main`: detects which add-ons had a monitored file change, then builds (and on push, publishes) only those whose `image:` is non-null. See the three build paths above.
- **`lint.yaml`** — on push/PR + nightly cron: runs `frenck/action-addon-linter` against every add-on directory. This is the lint gate; there is no local lint command — rely on the linter's rules for valid `config.yaml` structure.
- **`update-*.yaml`** — the five auto-bump cron jobs described above.

## Local development

To force the Supervisor to build an add-on locally during testing, ensure there is **no** `image:` key (most already lack one). For `papersome`/`storyteller`, temporarily comment out `image:` to build locally, and restore it before pushing.

There is no test suite and no local build/lint script in this repo — validation happens in CI (lint) and by installing the add-on in a running Home Assistant instance.
