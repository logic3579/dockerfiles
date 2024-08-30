# command to run network-tools
# docker run -it --rm --name test -d yakirinp/network-tools
#

FROM debian:sid-slim
MAINTAINER Yakir

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
