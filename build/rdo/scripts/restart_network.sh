#!/bin/bash

pkill -9 dnsmasq
systemctl restart openstack-nova-network
