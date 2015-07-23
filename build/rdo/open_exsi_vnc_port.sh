#!/bin/sh
#open firewall for vnc port

set -e;

cur_dir=$(cd `dirname $0`; pwd)
hosts_file=$cur_dir/esxi_hosts/hosts.cfg
vnc_file=$cur_dir/esxi_hosts//vnc.xml
for line in `cat $hosts_file`
do
   arr=(${line//|/ })
   num=${#arr[@]}
   if [ $num -lt 3 ]; then
      echo $line is not invalid
      exit 1
   fi
   address=${arr[0]}
   username=${arr[1]}
   password=${arr[2]}
   echo "begin to open vnc port for $address..."
   sshpass -p $password ssh $username@$address "cd /etc/vmware/firewall; if [ -e vnc.xml ]; then mv vnc.xml vnc.xml.bak; fi; exit"
   sshpass -p $password scp $vnc_file $username@$address:/etc/vmware/firewall/
   result=`sshpass -p $password ssh $username@$address "chmod -R 444 /etc/vmware/firewall/vnc.xml; esxcli network firewall refresh; esxcli network firewall ruleset list | grep VNC; exit 0"`
   if [ `echo $result|awk '{print $2}'` = "true" ]; then 
      echo "succeed to open esxi host vnc port for $address"
   else
      echo "failed to open esxi host vnc port for $address" 
   fi
   echo "end to vnc port operation"
done
