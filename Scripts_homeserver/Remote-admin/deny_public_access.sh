#!/bin/bash

/usr/sbin/iptables -t nat -D PREROUTING -p tcp --dport 48443 -j REDIRECT --to-port 28443
/usr/sbin/iptables -D INPUT -p tcp --dport 8443 -j ACCEPT
/usr/sbin/iptables -D INPUT -p tcp --dport 28443 -j ACCEPT
/usr/sbin/iptables -D INPUT -p tcp --dport 48443 -j ACCEPT
/usr/sbin/netfilter-persistent save &>/dev/null
