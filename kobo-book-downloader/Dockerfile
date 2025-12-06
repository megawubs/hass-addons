FROM ghcr.io/subdavis/kobodl:latest

# Install bash and jq for Home Assistant integration
RUN apk add --no-cache bash jq

# Copy the startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Use bash to run the script
CMD ["/bin/bash", "/run.sh"]
