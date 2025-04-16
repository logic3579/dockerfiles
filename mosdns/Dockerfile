# command to run
# docker run \
#     --name mosdns \
#     --restart always
#     -p 53:53/udp \
#     -p 53:53/tcp \
#     -v /etc/mosdns:/etc/mosdns
#     -d irinesistiana/mosdns

FROM irinesistiana/mosdns:v5.3.3
LABEL version="v5.3.3"
#COPY ./simple.config.yaml /etc/mosdns/config.yaml
COPY ./multi.config.yaml /etc/mosdns/config.yaml
COPY ./oisd_big_abp.txt /etc/mosdns/oisd_dbl_basic.txt
