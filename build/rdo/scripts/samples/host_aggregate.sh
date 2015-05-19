#!/bin/sh

# Parameters: aggr_name, host, tenant_ids
function create_aggr() {
    nova aggregate-create $1
    nova aggregate-add-host $1 $2

    tmpstring=$3
    tenants=${tmpstring//,/ } 
    tenant_ids=""
    for t in $tenants; do
        id=`keystone tenant-get $t | grep "^|\s*id\s*|" | awk '{print $4}'`
        if [ -n $id ]; then
            if [ -z $tenant_ids ]; then
                tenant_ids=$id
            else 
                tenant_ids="$tenant_ids,$id"
            fi
        fi
    done 

    nova aggregate-set-metadata $1 filter_tenant_id=[$tenant_ids]
}

# Parameters: aggr_name
function delete_aggr() {
    nova aggregate-delete $1
}

# Parameters: aggr_name, host
function aggr_remove_host() {
    nova aggregate-remove-host $1 $2
}

aggr_remove_host cluster01 juno01
delete_aggr cluster01
create_aggr cluster01 juno01 "admin,project01"
