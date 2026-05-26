# command to run system-tools
# docker run -it \
#    --rm \
#    --name system-tools \
#    -d logic3579/system-tools 
#

FROM alpine:3.23
MAINTAINER logic3579

RUN apk add --no-cache \
    bash \
    bmon \
    btop \
    coreutils \
    file \
    findutils \
    glances \
    grep \
    htop \
    iftop \
    iotop \
    jq \
    less \
    ltrace \
    lsof \
    nload \
    procps-ng \
    psmisc \
    strace \
    sysstat \
    util-linux

CMD [ "sh" ]
