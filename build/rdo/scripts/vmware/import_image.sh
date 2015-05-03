#!/bin/sh

image_name=$1 

nova image-delete $image_name

glance image-create \
        --name $image_name \
        --disk-format vmdk \
        --is-public True \
        --container-format bare \
        --property vmware_adaptertype="ide" \
        --property vmware_disktype="sparse" \
        --property hypervisor_type="vmware" \
     < $image_name-disk1.vmdk
