#!/bin/bash
# L2TP VPN Client installation script for CentOS 7
# yum -y install xl2tpd libreswan ipsec
#
if [ $# != 1 ] ; then
	echo "Usage: (sudo) sh $0 {init|start|stop}"
	exit 1;
fi

VPN_ADDR=XXX.XXX.XXX.XXX
IFACE=enp0s3

function getIP(){
    /sbin/ifconfig $1 |grep "inet "|awk '{print $2}'
}

function getGateWay(){
    /sbin/route -n |grep -m 1 "^0\.0\.0\.0" |awk '{print $2}'
}
function getVPNGateWay(){
    /sbin/route -n |grep -m 1 "$VPN_ADDR" |awk '{print $2}'
}

GW_ADDR=$(getGateWay)

function init(){
    cp ./options.l2tpd.client /etc/ppp/
    cp ./ipsec.conf /etc/
    cp ./ipsec.secrets /etc/
    cp ./xl2tpd.conf /etc/xl2tpd/
    systemctl restart ipsec.service
}

function start(){
    systemctl start xl2tpd.service
    /usr/sbin/ipsec auto --up L2TP-PSK
    /bin/echo "c vpn-connection" > /var/run/xl2tpd/l2tp-control
    sleep 5    #delay again to make that the PPP connection is up.

    ip route add $VPN_ADDR via $GW_ADDR dev $IFACE
    ip route del default via $GW_ADDR
    ip route add default via $(getIP ppp0)
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf
    echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
    ip route
    route -n
}

function stop(){
    /usr/sbin/ipsec auto --down L2TP-PSK
    /bin/echo "d vpn-connection" > /var/run/xl2tpd/l2tp-control
    systemctl stop xl2tpd.service

    VPN_GW=$(getVPNGateWay)
    ip route del $VPN_ADDR via $VPN_GW dev $IFACE
    ip route add default via $VPN_GW
    ip route
    route -n
}

$1
exit 0
