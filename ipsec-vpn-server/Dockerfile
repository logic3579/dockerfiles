# command to run ipsec-vpn-server
# docker run \
#     --name ipsec-vpn-server \
#     --env-file /opt/ipsec/vpn.env \
#     --restart=always \
#     -v ikev2-vpn-data:/etc/ipsec.d \
#     -v /lib/modules:/lib/modules:ro \
#     -p 500:500/udp \
#     -p 4500:4500/udp \
#     -d --privileged \
#     hwdsl2/ipsec-vpn-server

FROM hwdsl2/ipsec-vpn-server:latest
