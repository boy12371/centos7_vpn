L2TP VPN Server and Client Installation Script On CentOS7
=========================================================

# Install L2tp VPN Server
1. Install docker-engine
-  Install vpn server
```
sh vpn_server.sh
```

# Install L2tp VPN Client
1. Modify XXX of these files to yours
-  Install xl2tpd libreswan and ipsec
```
yum -y install epel-release net-tools wget
yum -y install strongswan xl2tpd
```
- start vpn client
```
sh vpn.sh init
sh vpn.sh start
```
- stop vpn client
```
sh vpn.sh stop
```
