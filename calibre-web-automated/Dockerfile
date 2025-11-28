FROM crocodilestick/calibre-web-automated

# Install jq for config parsing (if not already present)
RUN apk add --no-cache jq || true

# Copy custom init script to run before CWA starts
COPY run.sh /etc/cont-init.d/99-calibre-library-setup
RUN chmod a+x /etc/cont-init.d/99-calibre-library-setup