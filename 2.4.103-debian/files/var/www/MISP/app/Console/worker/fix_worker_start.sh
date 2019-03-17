#!/usr/bin/env bash
set -e 

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

STARTMSG="${Light_Green}[$0]${NC}"


CAKE_CMD="../cake CakeResque.CakeResque"
DEFAULT_USER="www-data"

# Extract base directory where this script is and cd into it
cd "${0%/*}" || exit

# # Check if run as root
# if [ "$EUID" -eq 0 ]; then
#     echo "$STARTMSG Please DO NOT run the worker script as root"
#     exit 1
# fi

check(){
    NAME="$1"
    WORKER_PID="$(ps faxo pid:1,cmd:1 |grep CakeResque | grep "$NAME" |grep -v grep |cut -f 1 -d ' ' )"
    [ -z "$WORKER_PID" ] && echo "no_worker"
    echo "$WORKER_PID"
}

start(){
    NAME="$1"
    [ -z "$NAME" ] && echo "$STARTMSG No Name. Exit now." && exit 1
    INTERVAL="$2"
    [ -z "$INTERVAL" ] && INTERVAL=5
    
    # Check if worker exists
    PID=$(check "$NAME")
    if [ "$PID" = "no_worker" ];then
        if [ "$NAME" = "scheduler" ]; then
           # Scheduler
           echo "$STARTMSG '$NAME' starting..."
           $CAKE_CMD startscheduler --interval "$INTERVAL"  --user $DEFAULT_USER --quiet &
           PID=$(check "$NAME")
           echo "$STARTMSG Worker '$NAME' started. PID=$PID."
        else
           # Workers
           echo "$STARTMSG Worker '$NAME' starting..."
           $CAKE_CMD start --interval "$INTERVAL" --queue "$NAME" --user $DEFAULT_USER --quiet &
           PID=$(check "$NAME")
           echo "$STARTMSG Worker '$NAME' started. PID=$PID."
        fi
    else
        for i in $PID
        do
            echo "$STARTMSG '$NAME' exists. PID=$i."
        done
    fi
    echo
}

restart_all(){
    $CAKE_CMD restart --user $DEFAULT_USER
    $CAKE_CMD stats
}

stop-all(){
    $CAKE_CMD stop -a 
    sleep 5
    $CAKE_CMD stats
}

############    MAIN    ################

# Parameter: start scheduler|default|prio|cache|email
[ "$1" = "start" ] && ( [ "$2" = "scheduler" ] || [ "$2" = "default" ] || [ "$2" = "prio" ] || [ "$2" = "cache" ] || [ "$2" = "email" ] ) && start "$2" && exit
# Parameter: '' OR start-all
if [ $# -lt 1 ] || [ "$1" = "start-all" ]; then
    echo "$STARTMSG No Parameter, check all"
    start "scheduler" 5
    start "default" 5
    start "prio" 5
    start "cache" 5
    start "email" 5
    exit
fi

# Parameter: stop-all
if [ "$1" = "stop-all" ];then
    stop-all
    exit
fi

# Parameter: restart-all
if [ "$1" = "restart-all" ];then
    restart_all
    exit
fi

# Parameter: One parameter but none of the above!
[ -n "$1" ] && echo "False parameter. Please use only:
    $0 start-all
    $0 start scheduler | default | prio | cache | email
    $0 stop-all
    $0 restart-all
    "

exit