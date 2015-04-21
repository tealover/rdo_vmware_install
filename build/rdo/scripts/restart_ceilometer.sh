#!/bin/bash

services="openstack-ceilometer-alarm-evaluator openstack-ceilometer-alarm-notifier openstack-ceilometer-api openstack-ceilometer-central openstack-ceilometer-collector openstack-ceilometer-compute openstack-ceilometer-notification"
for s in $services; do
    systemctl stop $s
done
for s in $services; do
    systemctl start $s
done
