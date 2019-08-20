#!/bin/bash
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
COUNTER="$(date +%Y-%m-%d_%H:%M)"
STARTMSG="${Light_Green}[ENTRYPOINT_CRON] [ $COUNTER ] ${NC}"


# Functions
echo (){
    command echo -e "$STARTMSG $*"
}

# Environment Parameter
    PATH_TO_MISP=${PATH_TO_MISP:-"/var/www/MISP"}
    CAKE=${CAKE:-"$PATH_TO_MISP/app/Console/cake"}
    INTERVAL=${1:-'3600'}   # Default 3600 seconds
    USER_ID=${2:-'1'}       # Default user id 1 admin@admin.test
    SERVER_IDS=${3:-'1'}

#
#   MAIN
#

# Exception Handling
    # Stop cronjob if it should be disabled
[ "${CRON_ENABLE-}" = "false" ] && echo "Stop cron job. Because it should be disabled." && exit 0
    # Allow to start the script only as www-data user
[ "$(whoami)" != "www-data" ] && echo "Please restart the script as www-data. Exit now." && exit 1


while(true)
do
    # Administering MISP via the CLI
        # Certain administrative tasks are exposed to the API, these help with maintaining and configuring MISP in an automated way / via external tools.:
        # GetSettings: MISP/app/Console/cake Admin getSetting [setting]
        # SetSettings: MISP/app/Console/cake Admin getSetting [setting] [value]
        # GetAuthkey: MISP/app/Console/cake Admin getauthkey [email]
        # SetBaseurl: MISP/app/Console/cake Baseurl setbaseurl [baseurl]
        # ChangePassword: MISP/app/Console/cake Password [email] [new_password]

    # Automating certain console tasks
        # If you would like to automate tasks such as caching feeds or pulling from server instances, you can do it using the following command line tools. Simply execute the given commands via the command line / create cron jobs easily out of them.:
        # Pull: MISP/app/Console/cake Server pull [user_id] [server_id] [full|update]
        # Push: MISP/app/Console/cake Server push [user_id] [server_id]
        # CacheFeed: MISP/app/Console/cake Server cacheFeed [user_id] [feed_id|all|csv|text|misp]
        # FetchFeed: MISP/app/Console/cake Server fetchFeed [user_id] [feed_id|all|csv|text|misp]
        # Enrichment: MISP/app/Console/cake Event enrichEvent [user_id] [event_id] [json_encoded_module_list]

    # START the SCRIPT
        # Set time and date
    COUNTER="$(date +%Y-%m-%d_%H:%M)"

        # Start Message
    echo "Start MISP-dockerized Cronjob at $COUNTER... "

    for SERVER_ID in $SERVER_IDS; do
        # Pull: MISP/app/Console/cake Server pull [user_id] [server_id] [full|update]
        echo "$CAKE Server pull $USER_ID..." && $CAKE Server pull "$USER_ID" "$SERVER_ID" full

        # Push: MISP/app/Console/cake Server push [user_id] [server_id]
        echo "$CAKE Server push $USER_ID..." && $CAKE Server push "$USER_ID" "$SERVER_ID"
    done

    # CacheFeed: MISP/app/Console/cake Server cacheFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$CAKE Server cacheFeed $USER_ID all..." && $CAKE Server cacheFeed "$USER_ID" all

    #FetchFeed: MISP/app/Console/cake Server fetchFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$CAKE Server fetchFeed $USER_ID all..." && $CAKE Server fetchFeed "$USER_ID" all
    
    # End Message
    echo "Finished MISP-dockerized Cronjob at $(date +%Y-%m-%d_%H:%M) and wait $INTERVAL seconds... "
    
    # Wait this time
    sleep "$INTERVAL"
done