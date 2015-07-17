#!/bin/sh

yum install -y patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/linux_net.py < ~/rdo/patches/linux_net_br100_promisc.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/api/openstack/compute/contrib/floating_ips.py < ~/rdo/patches/allocate_specific_floating_ip.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/api/openstack/compute/contrib/floating_ips_bulk.py < ~/rdo/patches/add_id_host_to_floating_ip.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/api/openstack/compute/contrib/os_networks.py < ~/rdo/patches/get_tenantid_from_parameters.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/api.py < ~/rdo/patches/add_impl_allocate_floating_ip.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/base_api.py < ~/rdo/patches/add_interface_allocate_floating_ip.patch
pkill -9 dnsmasq
systemctl restart openstack-nova-network
systemctl restart openstack-nova-api
