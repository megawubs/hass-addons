FROM ghcr.io/vito0912/abs-opds:2.0.4

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
