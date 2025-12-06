FROM koreader/kosync

# Install bash for the startup script
RUN apk add --no-cache bash

# Copy the startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Use the startup script
CMD ["/bin/bash", "/run.sh"]