#!/bin/bash
# L2TP VPN Client installation script for CentOS 7
# yum -y install xl2tpd libreswan ipsec
#
if [ $# != 1 ] ; then
	echo "Usage: (sudo) sh $0 {init|start|stop}"
	exit 1;
fi

VPN_SERVER_IP='your_vpn_server_ip'
VPN_IPSEC_PSK='your_ipsec_pre_shared_key'
VPN_USER='your_vpn_username'
VPN_PASSWORD='your_vpn_password'
IFACE='enp0s3'

function getIP(){
    /sbin/ifconfig $1 |grep "inet "|awk '{print $2}'
}

function getGateWay(){
    /sbin/route -n |grep -m 1 "^0\.0\.0\.0" |awk '{print $2}'
}
function getVPNGateWay(){
    /sbin/route -n |grep -m 1 "$VPN_SERVER_IP" |awk '{print $2}'
}

GW_ADDR=$(getGateWay)

function init(){
cat > /etc/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
  # strictcrlpolicy=yes
  # uniqueids = no

# Add connections here.

# Sample VPN connections

conn %default
  ikelifetime=60m
  keylife=20m
  rekeymargin=3m
  keyingtries=1
  keyexchange=ikev1
  authby=secret
  ike=aes128-sha1-modp1024,3des-sha1-modp1024!
  esp=aes128-sha1-modp1024,3des-sha1-modp1024!

conn myvpn
  keyexchange=ikev1
  left=%defaultroute
  auto=add
  authby=secret
  type=transport
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=$VPN_SERVER_IP
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_IPSEC_PSK"
EOF

chmod 600 /etc/ipsec.secrets

# For CentOS/RHEL & Fedora ONLY
mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.old 2>/dev/null
mv /etc/strongswan/ipsec.secrets /etc/strongswan/ipsec.secrets.old 2>/dev/null
ln -s /etc/ipsec.conf /etc/strongswan/ipsec.conf
ln -s /etc/ipsec.secrets /etc/strongswan/ipsec.secrets

cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac myvpn]
lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name $VPN_USER
password $VPN_PASSWORD
EOF

chmod 600 /etc/ppp/options.l2tpd.client
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control
systemctl restart strongswan
}

function start(){
    systemctl restart xl2tpd
    strongswan up myvpn
    echo "c myvpn" > /var/run/xl2tpd/l2tp-control
    sleep 5    #delay again to make that the PPP connection is up.

    ip route add $VPN_SERVER_IP via $GW_ADDR dev $IFACE
    ip route del default via $GW_ADDR
    ip route add default via $(getIP ppp0)
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf
    echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
    ip route
    route -n
    wget -qO- http://ipv4.icanhazip.com; echo
}

function stop(){
    /bin/echo "d myvpn" > /var/run/xl2tpd/l2tp-control
    strongswan down myvpn
    systemctl stop xl2tpd

    VPN_GW=$(getVPNGateWay)
    ip route del $VPN_SERVER_IP via $VPN_GW dev $IFACE
    ip route add default via $VPN_GW
    echo "nameserver $VPN_GW" > /etc/resolv.conf
    ip route
    route -n
    wget -qO- http://ipv4.icanhazip.com; echo
}

$1
exit 0
