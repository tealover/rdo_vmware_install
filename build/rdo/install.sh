#!/bin/bash

VCENTER_HOST=172.16.71.201
VCENTER_USER=root
VCENTER_PASSWORD=vmware
VCENTER_CLUSTER=cluster01
FIXED_IP_RANGE="10.0.0.0/24"
FLOAT_IP_RANGE="172.16.71.224/28"
ADMIN_PASSWORD="admin"

dt=`date '+%Y%m%d-%H%M%S'`
logfile="install_$dt.log"
answerfile="mystack.txt"

function add_hostname() {
    localip=`ifconfig | grep -v 127.0.0.1 | grep inet | grep -v inet6 | awk '{print $2}' | sed 's/addr://'`
    hostname=`hostname`
    sed -i "/.* $hostname/d" /etc/hosts
    echo "$localip $hostname" >> /etc/hosts
}

function pre_install() {
    yum install -y net-tools | tee -a $logfile 
    add_hostname
}

function modify_answerfile() {
    sed -i "s#^$1=.*#$1=$2#" $answerfile
}

function install_openstack() {
    yum install -y openstack-packstack | tee -a $logfile 
    
    pushd ~/rdo >/dev/null
    if [ ! -e $answerfile ]; then
        packstack  --gen-answer-file=$answerfile
        cp -n $answerfile ${answerfile}.bak
    fi

    nic=`ifconfig | grep flags | grep -v lo: | awk -F: '{print $1}'`

    modify_answerfile CONFIG_NEUTRON_INSTALL n
    modify_answerfile CONFIG_SWIFT_INSTALL n
    modify_answerfile CONFIG_CEILOMETER_INSTALL n
    modify_answerfile CONFIG_NAGIOS_INSTALL n
    modify_answerfile CONFIG_CEILOMETER_INSTALL y

    modify_answerfile CONFIG_VMWARE_BACKEND y
    modify_answerfile CONFIG_VCENTER_HOST $VCENTER_HOST
    modify_answerfile CONFIG_VCENTER_USER $VCENTER_USER
    modify_answerfile CONFIG_VCENTER_PASSWORD $VCENTER_PASSWORD
    modify_answerfile CONFIG_VCENTER_CLUSTER_NAME $VCENTER_CLUSTER
    modify_answerfile CONFIG_CINDER_BACKEND vmdk

    modify_answerfile CONFIG_NOVA_COMPUTE_PRIVIF $nic
    modify_answerfile CONFIG_NOVA_NETWORK_PRIVIF $nic
    modify_answerfile CONFIG_NOVA_NETWORK_PUBIF $nic
    modify_answerfile CONFIG_NOVA_NETWORK_FIXEDRANGE $FIXED_IP_RANGE
    modify_answerfile CONFIG_NOVA_NETWORK_FLOATRANGE $FLOAT_IP_RANGE

    modify_answerfile CONFIG_KEYSTONE_ADMIN_PW $ADMIN_PASSWORD
    modify_answerfile CONFIG_PROVISION_DEMO n

    packstack --answer-file=$answerfile

    echo ". ~/keystonerc_admin" > ~/.bash_profile
    . ~/.bash_profile

    ./import_image.sh vmware       # Import demo image

    popd >/dev/null
}

function post_install() {
    openstack-config --set /etc/nova/nova.conf DEFAULT public_interface br100
    systemctl restart openstack-nova-compute
    pkill -9 dnsmasq
    systemctl restart openstack-nova-network

    openstack-config --set /etc/nova/nova.conf DEFAULT notification_driver messaging
    openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
    systemctl restart openstack-nova-api

    openstack-config --set /etc/cinder/cinder.conf DEFAULT notification_driver messaging
    openstack-config --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
    systemctl restart openstack-cinder-api

    openstack-config --set /etc/glance/glance-api.conf DEFAULT notification_driver messaging
    openstack-config --set /etc/glance/glance-api.conf DEFAULT control_exchange glance
    systemctl restart openstack-glance-api
}

function apply_patches() {
    yum install -y patch
    patch -p1 /usr/lib/python2.7/site-packages/nova/network/linux_net.py < ~/rdo/patches/linux_net_br100_promisc.patch
    pkill -9 dnsmasq
    systemctl restart openstack-nova-network
}

pre_install
install_openstack
post_install
apply_patches
