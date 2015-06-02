#!/bin/sh

neutron net-create provider-101 --shared \
    --provider:physical_network external --provider:network_type vlan \
    --provider:segmentation_id 101
neutron subnet-create provider-101 192.168.206.0/24 --gateway 192.168.206.2
