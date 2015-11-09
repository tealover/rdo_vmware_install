#!/bin/sh

yum install -y patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/linux_net.py < ~/rdo/patches/linux_net_br100_promisc.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/api/openstack/compute/contrib/floating_ips.py < ~/rdo/patches/allocate_specific_floating_ip.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/api/openstack/compute/contrib/floating_ips_bulk.py < ~/rdo/patches/add_id_host_to_floating_ip.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/api/openstack/compute/contrib/os_networks.py < ~/rdo/patches/get_tenantid_from_parameters.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/api.py < ~/rdo/patches/add_impl_allocate_floating_ip.patch
patch -p1 /usr/lib/python2.7/site-packages/nova/network/base_api.py < ~/rdo/patches/add_interface_allocate_floating_ip.patch

vif_ha=`openstack-config --get /etc/nova/nova.conf vmware vlan_interface_ha`
if [ -z $vif_ha ]; then
  echo "set nova-compute link to vmware support multi vlan interfaces"
  openstack-config --set /etc/nova/nova.conf vmware vlan_interface_ha vmnic0
  cp /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/network_util.py /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/network_util.py.bak
  patch -p1 /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/network_util.py < ~/rdo/patches/network_util_support_vmware_multi_vlan_interfaces.patch

  cp /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/vif.py /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/vif.py.bak
  patch -p1 /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/vif.py < ~/rdo/patches/vif_support_multi_vmware_vlan_interfaces.patch
else
  echo "nova-compute link to vmware has supported multi physical vlan interfaces"
fi

pkill -9 dnsmasq
systemctl restart openstack-nova-network
systemctl restart openstack-nova-api
