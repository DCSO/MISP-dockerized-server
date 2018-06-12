#!/bin/bash
set -e

function init_apache() {
# Apache gets grumpy about PID files pre-existing
rm -f /run/apache2/apache2.pid
# start Workers for MISP
su -s /bin/bash -c "/var/www/MISP/app/Console/worker/start.sh" www-data

#exec apache2 -DFOREGROUND
/usr/sbin/apache2ctl -DFOREGROUND $1
}

init_apache $CMD_APACHE