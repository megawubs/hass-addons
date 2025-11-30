FROM 00jlich/abs-kosync-bridge:latest

# Switch to root to install packages
USER root

# Copy our wrapper script
COPY run.sh /usr/local/bin/run.sh
RUN chmod a+x /usr/local/bin/run.sh

# Keep running as root for Home Assistant integration

# Use bash to run our wrapper which sets env vars then starts the bridge
CMD ["/bin/bash", "/usr/local/bin/run.sh"]
