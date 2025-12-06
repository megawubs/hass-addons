FROM ghcr.io/subdavis/kobodl:latest

# Install bash and jq for Home Assistant integration
RUN apk add --no-cache bash jq

# Copy the startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Override the entrypoint and use bash to run the script
ENTRYPOINT []
CMD ["/bin/bash", "/run.sh"]
