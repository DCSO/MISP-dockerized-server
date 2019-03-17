#!/bin/bash
set -e

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

STARTMSG="${Light_Green}[ENTRYPOINT_WORKERS]${NC}"
CAKE_CMD="/var/www/MISP/app/Console/cake CakeResque.CakeResque"


# Wait until entrypoint apache is ready
while (true)
do
    sleep 2
    [ -f /entrypoint_apache.install ] && continue
    break
done


# start Workers for MISP
echo "$STARTMSG Start Workers..."
#su -s /bin/bash -c "/var/www/MISP/app/Console/worker/start.sh" www-data
#/var/www/MISP/app/Console/worker/start.sh
/var/www/MISP/app/Console/worker/fix_worker_start.sh start-all
echo "$STARTMSG Start Workers...finished"

while true
do
    sleep 3600
    echo "$STARTMSG Start Workers..."
    /var/www/MISP/app/Console/worker/fix_worker_start.sh start-all
    echo "$STARTMSG Start Workers...finished"
done
