L2TP VPN Server and Client Installation Script On CentOS7
=========================================================

# Install L2tp VPN Server
1. Install docker-engine
-  
```
sh vpn_server.sh
```

# Install L2tp VPN Client
1.
```
yum -y install xl2tpd libreswan ipsec
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
