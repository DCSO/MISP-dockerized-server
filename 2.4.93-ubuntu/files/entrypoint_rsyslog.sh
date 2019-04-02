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




# write supervisord configuration
cat << EOF > /etc/rsyslog.d/rsyslog_custom.conf
#
# https://www.slideshare.net/rainergerhards1/using-wildcards-with-rsyslogs-file-monitor-imfile
module(load="imfile")
# Apache2
input (type="imfile" tag="apache.info" file="/var/log/apache2/access.log")
input (type="imfile" tag="apache.info" file="/var/log/apache2/other_vhosts_access.log")
input (type="imfile" tag="apache.error" file="/var/log/apache2/error.log")
# MISP
input (type="imfile" tag="misp.error" file="/var/www/MISP/app/tmp/logs/error.log")
# Cake
input (type="imfile" tag="worker.error" file="/var/www/MISP/app/tmp/logs/resque-worker-error.log")
input (type="imfile" tag="scheduler.error" file="/var/www/MISP/app/tmp/logs/resque-scheduler-error.log")
input (type="imfile" tag="resque.debug" file="/var/www/MISP/app/tmp/logs/resque-*.log")
# ZeroMQ
input (type="imfile" tag="mispzmq.info" file="/var/www/MISP/app/tmp/logs/mispzmq.log")
input (type="imfile" tag="mispzmq.error" file="/var/www/MISP/app/tmp/logs/mispzmq.error.log")


# all info and debug tagged messages to stdout
*.info;\
    *.debug /dev/stdout

# all error and emerg tagged messages to stderr
*.error;\
    *.emerg /dev/stderr

# discard all other:
& stop

# all other
*.* /dev/stdout

EOF


echo "$STARTMSG Start rsyslogd" && rsyslogd -n
