FROM ghcr.io/cporcellijr/abs-kosync-bridge:latest

USER root
RUN apt-get update && apt-get install -y jq

COPY run.sh /usr/local/bin/run.sh
RUN chmod a+x /usr/local/bin/run.sh

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
