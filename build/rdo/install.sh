#!/bin/bash

VCENTER_HOST=172.16.71.201
VCENTER_USER=root
VCENTER_PASSWORD=vmware
GLANCE_DATACENTER=dc01
VCENTER_CLUSTER=cluster01
GLANCE_DATASTORE=os_datastore02
GLANCE_IMAGE_PATH=/openstack_glance

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

    sed -i "s#config     => \$config_file,#config     => \$config_file,\n  pidfilepath => '/var/run/mongodb/mongodb.pid',#" /usr/lib/python2.7/site-packages/packstack/puppet/templates/mongodb.pp

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
    popd >/dev/null
}

# Modify openstack configurations
function post_install() {
    # nova
    openstack-config --set /etc/nova/nova.conf DEFAULT public_interface br100
    openstack-config --set /etc/nova/nova.conf DEFAULT compute_monitors ComputeDriverCPUMonitor
    systemctl restart openstack-nova-compute
    systemctl restart openstack-nova-scheduler
    systemctl restart openstack-nova-conductor
    pkill -9 dnsmasq
    systemctl restart openstack-nova-network

    openstack-config --set /etc/nova/nova.conf DEFAULT notification_driver messaging
    openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
    openstack-config --set /etc/nova/nova.conf DEFAULT control_exchange nova
    systemctl restart openstack-nova-api

    # cinder
    openstack-config --set /etc/cinder/cinder.conf DEFAULT notification_driver messaging
    openstack-config --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
    systemctl restart openstack-cinder-api

    # glance
    openstack-config --set /etc/glance/glance-api.conf DEFAULT notification_driver messaging
    openstack-config --set /etc/glance/glance-api.conf DEFAULT control_exchange glance
    openstack-config --set /etc/glance/glance-api.conf DEFAULT default_store vsphere
    openstack-config --set /etc/glance/glance-api.conf glance_store vmware_server_host $VCENTER_HOST
    openstack-config --set /etc/glance/glance-api.conf glance_store vmware_server_username $VCENTER_USER
    openstack-config --set /etc/glance/glance-api.conf glance_store vmware_server_password $VCENTER_PASSWORD
    openstack-config --set /etc/glance/glance-api.conf glance_store vmware_datacenter_path $GLANCE_DATACENTER
    openstack-config --set /etc/glance/glance-api.conf glance_store vmware_datastore_name $GLANCE_DATASTORE
    openstack-config --set /etc/glance/glance-api.conf glance_store vmware_store_image_dir $GLANCE_IMAGE_PATH
    openstack-config --set /etc/glance/glance-api.conf glance_store stores glance.store.vmware_datastore.Store
    systemctl restart openstack-glance-api
    systemctl restart openstack-glance-registry

    # ceilometer
    openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT hypervisor_inspector vsphere
    openstack-config --set /etc/ceilometer/ceilometer.conf vmware host_ip $VCENTER_HOST
    openstack-config --set /etc/ceilometer/ceilometer.conf vmware host_username $VCENTER_USER
    openstack-config --set /etc/ceilometer/ceilometer.conf vmware host_password $VCENTER_PASSWORD
    systemctl restart openstack-ceilometer-central
    systemctl restart openstack-ceilometer-collector
    systemctl restart openstack-ceilometer-compute
}

function apply_patches() {
    yum install -y patch
    patch -p1 /usr/lib/python2.7/site-packages/nova/network/linux_net.py < ~/rdo/patches/linux_net_br100_promisc.patch
    pkill -9 dnsmasq
    systemctl restart openstack-nova-network
}

function import_image() {
    pushd ~/rdo >/dev/null
    ./import_image.sh vmware       # Import demo image
    popd >/dev/null
}

pre_install
install_openstack
post_install
apply_patches
import_image
