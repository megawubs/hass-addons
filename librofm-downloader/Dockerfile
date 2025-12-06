ARG BUILD_FROM=ghcr.io/hassio-addons/base:16.3.2
FROM ghcr.io/burntcookie90/librofm-downloader

# Install bash and jq for Home Assistant integration
RUN apk add --no-cache bash jq

# Copy the startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Use bash to run the script (tini is the entrypoint from base image)
CMD ["/bin/bash", "/run.sh"]
