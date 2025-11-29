FROM ghcr.io/vito0912/abs-opds:2.0.4

# Switch to root to install packages
USER root

# Install jq for config parsing
RUN apk add --no-cache jq bash

# Copy our custom run script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Switch back to node user (original user from base image)
USER node

# Use our run script as the entry point
CMD ["run.sh"]
