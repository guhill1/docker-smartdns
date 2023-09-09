#!/bin/sh
#if [ ! -f /etc/smartdns/smartdns.conf ]; then
#	mkdir -p /etc/smartdns
#	cp -u /smartdns.conf /etc/smartdns/smartdns.conf
#fi
/usr/sbin/smartdns -f -x -c /etc/smartdns/smartdns.conf
