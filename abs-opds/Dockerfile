# Temporarily built from megawubs/abs-opds instead of upstream, to test the
# OPDS Content-Type fix on branch fix/opds-content-type before offering it to
# Vito0912/abs-opds as a pull request. To revert once that is merged and
# released: restore `FROM ghcr.io/vito0912/abs-opds:2.0.4` here and bump the
# version in config.yaml to 2.0.4-beta-7. Note "bump", not "revert" -- Home
# Assistant needs the version to sort above the installed one, so going back
# to 2.0.4-beta-5 would leave the add-on stuck on this build.
#
# Pinned by digest rather than the mutable :dev tag, so a rebuild cannot
# silently reuse a stale cached image and make the fix look broken.
# Digest of :dev at megawubs/abs-opds 571b953.
FROM ghcr.io/megawubs/abs-opds@sha256:6181ef170fb3fa4a1c9449310e6904724ae1b6123150831b09ac9abb3868d4b1

# Switch to root to install packages
USER root

# Install jq and bash for our wrapper script
RUN apk add --no-cache jq bash

# Copy our wrapper script
COPY run.sh /usr/local/bin/run.sh
RUN chmod a+x /usr/local/bin/run.sh

# Keep running as root for Home Assistant integration
# (the wrapper script needs to read /data/options.json)

# Use bash to run our wrapper which sets env vars then calls npm start
CMD ["/bin/bash", "/usr/local/bin/run.sh"]
