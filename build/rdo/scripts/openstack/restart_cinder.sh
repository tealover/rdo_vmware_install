#!/bin/bash

services="openstack-cinder-api openstack-cinder-scheduler openstack-cinder-volume"
for s in $services; do
    systemctl stop $s
done
for s in $services; do
    systemctl start $s
done
