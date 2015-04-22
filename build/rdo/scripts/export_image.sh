#!/bin/sh

vmname=$1
rm -f $vmname*

ovftool --noSSLVerify --diskMode=monolithicSparse vi://root@172.16.71.203/$vmname $vmname.ovf <<EOF
abcd1234
EOF
