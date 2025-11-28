FROM crocodilestick/calibre-web-automated

# Install jq for config parsing (if not already present)
RUN apk add --no-cache jq || true

# Create s6-overlay v3 service directory for our custom init
RUN mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d && \
    mkdir -p /etc/s6-overlay/s6-rc.d/calibre-library-setup

# Copy init script as 'up' (oneshot services use 'up', not 'run')
COPY run.sh /etc/s6-overlay/s6-rc.d/calibre-library-setup/up
RUN chmod a+x /etc/s6-overlay/s6-rc.d/calibre-library-setup/up

# Create service type file (oneshot = runs once during init)
RUN echo "oneshot" > /etc/s6-overlay/s6-rc.d/calibre-library-setup/type

# Add our service to user bundle so it runs during init
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/calibre-library-setup