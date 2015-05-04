#!/bin/bash

VCENTER_IP=192.168.206.140
USERNAME=root
PASSWORD=vmware

VLAN_RANGE_START=101
VLAN_RANGE_END=110
NFS_SERVER_IP=192.168.206.147
NFS_SHARE="/mnt/vg01/vol01/share01 /mnt/vg01/vol02/share02"

function exec_cmd() {
    esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP $@
}

function init_network() {
    for((i=$VLAN_RANGE_START;i<=$VLAN_RANGE_END;i++)); do
        exec_cmd network vswitch standard portgroup add -p br${i} -v vSwitch0
        exec_cmd network vswitch standard portgroup set -p br${i} -v $i
    done
}

function init_storage() {
    for i in $NFS_SHARE; do
        vol=`basename $i`
        exec_cmd storage nfs add --host $NFS_SERVER_IP --share /mnt/vg01/lv01/$i --volume-name=$vol
        echo $i
    done
    local_datastore=`esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP storage filesystem list | grep VMFS-5 | cut -f1 -d ' '`
    exec_cmd storage filesystem unmount -p $local_datastore
}

function enable_vnc() {
    scp vnc.xml root@$ESX_IP:/etc/vmware/firewall
    exec_cmd network firewall refresh
}

if [ -z $1 ]; then
    echo "Usage: $0 <esx_host_ip>"
    exit 
fi

ESX_IP=$1
init_network
init_storage
enable_vnc
