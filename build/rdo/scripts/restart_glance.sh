#!/bin/bash

services="openstack-glance-api openstack-glance-registry"
for s in $services; do
    systemctl stop $s
done
for s in $services; do
    systemctl start $s
done
