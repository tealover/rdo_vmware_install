#!/bin/bash

ESX_IP=192.168.1.109

VCENTER_IP=192.168.1.107
USERNAME=root
PASSWORD=vmware

VLAN_RANGE_START=101
VLAN_RANGE_END=110
NFS_SERVER_IP=192.168.1.102

function init_network() {
    for((i=$VLAN_RANGE_START;i<=$VLAN_RANGE_END;i++)); do
        esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP network vswitch standard portgroup add -p br${i} -v vSwitch0
        esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP network vswitch standard portgroup set -p br${i} -v $i
    done
}

function init_storage() {
    esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP storage nfs add --host $NFS_SERVER_IP --share /mnt/vg01/lv01/share01 --volume-name=share01
    esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP storage nfs add --host $NFS_SERVER_IP --share /mnt/vg01/lv02/share02 --volume-name=share02
    esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP storage nfs add --host $NFS_SERVER_IP --share /mnt/vg01/lv03/share03 --volume-name=share03

    local_datastore=`esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP storage filesystem list | grep VMFS-5 | cut -f1 -d ' '`
    esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP storage filesystem unmount -p $local_datastore
}

function enable_vnc() {
    scp vnc.xml root@$ESX_IP:/etc/vmware/firewall
    esxcli -s $VCENTER_IP -u $USERNAME -p $PASSWORD -h $ESX_IP network firewall refresh
}

init_network
init_storage
enable_vnc
