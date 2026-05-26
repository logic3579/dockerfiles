# command to run network-tools
# docker run -it \
#    --rm \
#    --name network-tools\
#    -d logic3579/network-tools
#

FROM alpine:3.23
MAINTAINER logic3579

RUN apk add --no-cache \
    apache2-utils \
    bind-tools \
    busybox-extras \
    ca-certificates \
    curl \
    drill \
    ethtool \
    iperf3 \
    iproute2 \
    iputils \
    mtr \
    netcat-openbsd \
    nmap \
    openssh-client-default \
    openssl \
    socat \
    tcpdump \
    traceroute \
    wget \
    whois

CMD [ "sh" ]
