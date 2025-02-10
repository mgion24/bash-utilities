#!/bin/bash

/usr/sbin/iptables -A INPUT -p tcp --dport 24248 -j ACCEPT
/usr/sbin/iptables -t nat -A PREROUTING -p tcp --dport 24248 -j REDIRECT --to-port 22
/usr/sbin/netfilter-persistent save &>/dev/null
/usr/sbin/usermod -aG www-data marian
