# command to run network-tools
# docker run -it \
#    --rm \
#    --name network-tools\
#    -d logic3579/network-tools

FROM debian:sid-slim
MAINTAINER Logic

RUN apt update && apt install -y \
    apache2-utils \
    curl \
    inetutils-ping \
    iproute2 \
    netcat-openbsd \
    tcpdump \
    telnet \
    traceroute \
    wget \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

CMD [ "bash" ]
