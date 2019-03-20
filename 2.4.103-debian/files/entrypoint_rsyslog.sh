#!/bin/bash
set -e

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

STARTMSG="${Light_Green}[ENTRYPOINT_RSYSLOG]${NC}"

# delete old logs
[ -z "$DELETE_LOG" ] && export DELETE_LOG="yes"
[ "$DELETE_LOG" = "yes" ] && echo "$STARTMSG delete old MISP logs: rm -f /var/www/MISP/app/tmp/logs/*" && rm -f /var/www/MISP/app/tmp/logs/*


echo "$STARTMSG Start rsyslogd" && rsyslogd -n
