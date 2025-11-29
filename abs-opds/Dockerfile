FROM ghcr.io/vito0912/abs-opds:2.0.4

# Install jq for config parsing
RUN apk add --no-cache jq bash

# Copy our custom run script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Use our run script as the entry point
CMD ["/run.sh"]
