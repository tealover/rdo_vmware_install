#!/bin/sh
#公安厅项目中需要支持vlan_interface支持两块网卡的配置

yum install -y patch

vif_ha=`openstack-config --get /etc/nova/nova.conf vmware vlan_interface_ha`
if [ -z $vif_ha ]; then
  echo "set nova-compute link to vmware support multi vlan interfaces"
  openstack-config --set /etc/nova/nova.conf vmware vlan_interface_ha vmnic0
  cp /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/network_util.py /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/network_util.py.bak
  patch -p1 /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/network_util.py < ~/rdo/patches/network_util_support_vmware_multi_vlan_interfaces.patch

  cp /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/vif.py /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/vif.py.bak
  patch -p1 /usr/lib/python2.7/site-packages/nova/virt/vmwareapi/vif.py < ~/rdo/patches/vif_support_multi_vmware_vlan_interfaces.patch
  pkill -9 dnsmasq
  systemctl restart openstack-nova-network
else
  echo "nova-compute link to vmware has supported multi physical vlan interfaces"
fi




