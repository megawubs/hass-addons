FROM crocodilestick/calibre-web-automated

# Copy startup script
COPY run.sh /
RUN chmod a+x /run.sh

# Use custom startup script
CMD ["/run.sh"]