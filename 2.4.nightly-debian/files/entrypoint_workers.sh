#!/bin/bash
set -eu

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[ENTRYPOINT_WORKERS]${NC}"
PATH_TO_MISP="/var/www/MISP"
CAKE_CMD="${PATH_TO_MISP}/app/Console/cake CakeResque.CakeResque"

echo (){
    command echo -e "$STARTMSG $*"
}


# Allow to start the script only as www-data user
[ "$(whoami)" != "www-data" ] && echo "Please restart the script as www-data. Exit now." && exit 1


#
# Check if Apache2 is available
#
    # Function to check if apache2 is available
URL="https://localhost/"
isApache2up() {
    curl -fks https://localhost/
    command echo $?
}
    # Try 100 times to reach Apache2, after this exit with error.
RETRY=100
# shellcheck disable=SC2046
until [ $(isApache2up) -eq 0 ] || [ $RETRY -le 0 ] ; do
    echo "Waiting for Apache2 to come up ..."
    sleep 5
    # shellcheck disable=SC2004
    RETRY=$(( $RETRY - 1))
done
    # Check if RETRY=0 then exit or start workers script
if [ $RETRY -le 0 ]; then
    >&2 echo "Error: Could not connect to Apache2 on $URL"
    exit 1
else
    # start Workers for MISP
    echo "Start Workers ..."
    chmod +x ${PATH_TO_MISP}/app/Console/worker/start.sh
    /var/www/MISP/app/Console/worker/start.sh
    echo "Start Workers ... finished"
fi


