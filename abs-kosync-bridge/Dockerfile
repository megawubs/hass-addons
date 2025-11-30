FROM 00jlich/abs-kosync-bridge:latest

# Switch to root to install packages
USER root
RUN apt-get update && apt-get install -y \
      jq

# Copy our wrapper script
COPY run.sh /usr/local/bin/run.sh
RUN chmod a+x /usr/local/bin/run.sh

RUN echo 'source /etc/profile.d/addon-env.sh 2>/dev/null || true' >> /root/.bashrc

# Keep running as root for Home Assistant integration

# Use bash to run our wrapper which sets env vars then starts the bridge
CMD ["/bin/bash", "/usr/local/bin/run.sh"]
