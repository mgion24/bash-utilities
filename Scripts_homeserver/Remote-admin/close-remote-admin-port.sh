#!/bin/bash

/usr/sbin/iptables -t nat -D PREROUTING -p tcp --dport 24248 -j REDIRECT --to-port 22
/usr/sbin/iptables -D INPUT -p tcp --dport 24248 -j ACCEPT
/usr/sbin/netfilter-persistent save &>/dev/null
/usr/bin/gpasswd -d marian www-data
