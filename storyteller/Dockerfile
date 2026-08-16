# Storyteller publishes a ready-to-run image, so this add-on only layers a thin
# wrapper on top of it. That wrapper is unavoidable now: Home Assistant hands an
# add-on its configuration as JSON in /data/options.json, Storyteller is
# configured through environment variables, and since web-v2 it refuses to start
# unless a secret key is provided.
#
# There is deliberately no `image:` key in config.yaml, so the Supervisor builds
# this on the user's device and the CI builder skips it. That is cheap: every
# expensive layer already lives in the upstream image.
ARG STORYTELLER_VERSION=web-v2.14.20
FROM registry.gitlab.com/storyteller-platform/storyteller:${STORYTELLER_VERSION}

# The upstream image is Ubuntu based (see upstream's Dockerfile.base), so apt,
# not apk. Only jq is missing; bash, coreutils, gosu and tini are all already
# there for upstream's own entrypoint.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/run.sh
RUN chmod a+x /usr/local/bin/run.sh

# Declaring ENTRYPOINT resets the CMD inherited from the base image, so
# upstream's default command has to be repeated here. run.sh translates the
# add-on options into environment variables and then execs upstream's own
# entrypoint with this command, leaving tini and the uid/gid handling to it.
ENTRYPOINT ["/usr/local/bin/run.sh"]
CMD ["node", "--enable-source-maps", "server.js"]
