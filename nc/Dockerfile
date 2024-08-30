# command to run nc
# docker run -it --rm \
#    yakirinp/nc www.google.com 443
#

FROM alpine:latest
MAINTAINER Yakir

RUN apk add --no-cache --virtual \
        busybox-extras

ENTRYPOINT [ "nc", "-zv" ]
