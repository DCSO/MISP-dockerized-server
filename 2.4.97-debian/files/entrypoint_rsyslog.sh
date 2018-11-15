#!/bin/sh

# delete old logs
[ -z "$DELETE_LOG" ] && export DELETE_LOG=yes
[ "$DELETE_LOG" == "no" ] && echo "delete old MISP logs: rm -f /var/www/MISP/app/tmp/logs/*" && rm -f /var/www/MISP/app/tmp/logs/*

rsyslogd -n