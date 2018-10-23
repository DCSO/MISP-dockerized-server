#!/bin/bash
set -ex

function init_netdata(){

    CONFIG_FILE="/etc/netdata/netdata.conf"

    sed -i "s/.*# hostname.*/hostname = $(hostname)/" $CONFIG_FILE
    #sed -i "s,.*# error log.*,error log = /dev/stderr," $CONFIG_FILE
    #sed -i "s,.*# access log.*,access log = /dev/stdout," $CONFIG_FILE
    sed -i "s/.*# memory mode.*/memory mode = ram/" $CONFIG_FILE

    /usr/sbin/netdata -D

}

function start_monitoring(){
    # Init and start Netdata as monitoring solution
    init_netdata
}


#####    MAIN   #####
start_monitoring