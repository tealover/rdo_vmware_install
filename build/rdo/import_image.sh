#!/bin/sh

glance image-create \
    --name cirros \
    --disk-format vmdk \
    --is-public True \
    --container-format bare \
    --property vmware_adaptertype="ide" \
    --property vmware_disktype="sparse" \
    --property hypervisor_type="vmware" \
     < cirros-0.3.3-x86_64-ide.vmdk
