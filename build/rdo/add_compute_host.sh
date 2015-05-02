#!/bin/bash

CONTROLLER_HOST=172.16.71.204
NEW_COMPUTE_HOST=172.16.71.205
VMWARE_CLUSTER_NAME=cluster02
FIXED_IP_RANGE="10.0.0.0/16"
EXCLUDE_SERVERS=$CONTROLLER_HOST

answerfile="mystack.txt"

function install_openstack() {
    cp $answerfile ${answerfile}_add_node
    sed -i "s/^CONFIG_COMPUTE_HOSTS.*$/&,$NEW_COMPUTE_HOST/" ${answerfile}_add_node
    sed -i "s/^CONFIG_NETWORK_HOSTS.*$/&,$NEW_COMPUTE_HOST/" ${answerfile}_add_node
    sed -i "s/^CONFIG_VCENTER_CLUSTER_NAME=.*/CONFIG_VCENTER_CLUSTER_NAME=$VMWARE_CLUSTER_NAME/" ${answerfile}_add_node
    sed -i "s/^EXCLUDE_SERVERS=.*/EXCLUDE_SERVERS=$EXCLUDE_SERVERS/" ${answerfile}_add_node

    packstack --answer-file=${answerfile}_add_node
}

function pre_install() {
    ssh-copy-id root@$NEW_COMPUTE_HOST
}

function post_install() {
    ssh $NEW_COMPUTE_HOST "iptables -t nat -I POSTROUTING -s $FIXED_IP_RANGE ! -d $FIXED_IP_RANGE -j MASQUERADE; service iptables save"
    ssh $NEW_COMPUTE_HOST "/root/rdo/apply_patch.sh"
}

pre_install
install_openstack
post_install
