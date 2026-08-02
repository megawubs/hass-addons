# Changelog

## 0.3.3

Initial release, packaging [opds-proxy][upstream] 0.3.3.

- Configure OPDS feeds, optionally with stored basic-auth credentials, from the
  add-on options.
- Cookie signing keys are generated once and persisted, so sessions survive
  restarts.
- EPUB to KEPUB conversion for Kobo devices.
- Optional `config.yml` override via the add-on configuration folder.

[upstream]: https://github.com/evan-buss/opds-proxy
