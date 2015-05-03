#!/bin/bash

services="openstack-nova-consoleauth openstack-nova-novncproxy openstack-nova-cert openstack-nova-conductor openstack-nova-scheduler openstack-nova-api openstack-nova-compute"
for s in $services; do
    systemctl stop $s
done
for s in $services; do
    systemctl start $s
done
