#!/bin/sh

yum install -y patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/linux_net.py < ~/rdo/patches/linux_net_br100_promisc.patch
pkill -9 dnsmasq
systemctl restart openstack-nova-network
