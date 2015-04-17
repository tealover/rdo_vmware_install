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

function pre_install() {
    yum install -y net-tools | tee -a $logfile 
}

function add_hostname() {
    localip=`ifconfig | grep -v 127.0.0.1 | grep inet | grep -v inet6 | awk '{print $2}' | sed 's/addr://'`
    hostname=`hostname`
    sed -i "/.* $hostname/d" /etc/hosts
    echo "$localip $hostname" >> /etc/hosts
}

function set_parameter() {
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

    set_parameter CONFIG_NEUTRON_INSTALL n
    set_parameter CONFIG_SWIFT_INSTALL n
    set_parameter CONFIG_CEILOMETER_INSTALL n
    set_parameter CONFIG_NAGIOS_INSTALL n
    set_parameter CONFIG_VMWARE_BACKEND y
    set_parameter CONFIG_VCENTER_HOST $VCENTER_HOST
    set_parameter CONFIG_VCENTER_USER $VCENTER_USER
    set_parameter CONFIG_VCENTER_PASSWORD $VCENTER_PASSWORD
    set_parameter CONFIG_VCENTER_CLUSTER_NAME $VCENTER_CLUSTER
    set_parameter CONFIG_CINDER_BACKEND vmdk
    set_parameter CONFIG_NOVA_COMPUTE_PRIVIF $nic
    set_parameter CONFIG_NOVA_NETWORK_PRIVIF $nic
    set_parameter CONFIG_NOVA_NETWORK_PUBIF $nic
    set_parameter CONFIG_NOVA_NETWORK_FIXEDRANGE $FIXED_IP_RANGE
    set_parameter CONFIG_NOVA_NETWORK_FLOATRANGE $FLOAT_IP_RANGE
    set_parameter CONFIG_KEYSTONE_ADMIN_PW $ADMIN_PASSWORD
    set_parameter CONFIG_PROVISION_DEMO n

    packstack --answer-file=$answerfile

    echo ". ~/keystonerc_admin" > ~/.bash_profile
    . ~/.bash_profile

    ./import_image.sh       # Import demo image

    popd >/dev/null
}

pre_install
add_hostname
install_openstack
