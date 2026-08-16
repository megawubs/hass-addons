# Changelog

## web-v2.14.20

Updates [Storyteller][upstream] from `web-v1.4.0-ctc.6` to `web-v2.14.20`. The
old pin was an experimental build off a side branch, not a release, and nothing
was tracking it — see `DOCS.md` for what to do before updating.

- Adds a daily workflow that follows upstream's `web-vX.Y.Z` releases, so this
  cannot silently fall behind again.
- The instance secret key is generated and persisted on first start. The old
  build fell back to a hard-coded, publicly known key, so every existing login
  is invalidated by this update.
- New options: `log_level`, `enable_web_reader`, `secret_key` and `auth_url`.
  Storyteller settings can also be managed declaratively through a
  `storyteller.json` in the add-on's config folder.
- The add-on is now built on your device on top of the upstream image, which is
  what makes the options above possible.
- Dropped `armv7` from the supported architectures: upstream has never published
  an image for it.

[upstream]: https://gitlab.com/storyteller-platform/storyteller
