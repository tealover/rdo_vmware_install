#!/bin/bash

CONTROLLER_HOST=192.168.145.23
NEW_COMPUTE_HOST=192.168.145.24
VMWARE_CLUSTER_NAME=cluster02

answerfile="mystack.txt"

cp $answerfile ${answerfile}_add_node
sed -i "s/^CONFIG_COMPUTE_HOSTS.*$/&,$NEW_COMPUTE_HOST/" ${answerfile}_add_node
sed -i "s/^CONFIG_NETWORK_HOSTS.*$/&,$NEW_COMPUTE_HOST/" ${answerfile}_add_node
sed -i "s/^CONFIG_VCENTER_CLUSTER_NAME=.*/CONFIG_VCENTER_CLUSTER_NAME=$VMWARE_CLUSTER_NAME/" ${answerfile}_add_node
sed -i "s/^EXCLUDE_SERVERS=.*/EXCLUDE_SERVERS=$CONTROLLER_HOST/" ${answerfile}_add_node

packstack --answer-file=${answerfile}_add_node
