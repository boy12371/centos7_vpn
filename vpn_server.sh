#!/bin/bash
#
PSK=`tr -cd '[:alnum:]' < /dev/urandom | fold -w8 | head -n1`
PASSWORD=`tr -cd '0-9' < /dev/urandom | fold -w8 | head -n1`
docker stop l2tp
docker rm l2tp
docker run -d \
--name l2tp \
--net=host  \
--restart always \
--cap-add NET_ADMIN \
-p 500:500/udp \
-p 4500:4500/udp \
-p 1701:1701/tcp \
-p 1194:1194/udp \
-e PSK=$PSK \
-e USERNAME=richard \
-e PASSWORD=$PASSWORD \
siomiz/softethervpn
echo "PSK=$PSK"
echo 'USERNAME=richard'
echo "PASSWORD=$PASSWORD"
