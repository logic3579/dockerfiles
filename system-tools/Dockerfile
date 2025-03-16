# command to run system-tools
# docker run -it --rm --name test -d yakir3/system-tools 
#

FROM ubuntu:devel
MAINTAINER Yakir

RUN apt update && apt install -y \
    dstat \
    glances \
    iftop \
    iotop \
    lsof \
    nload \
    procps \
    sysstat \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

CMD [ "bash" ]
