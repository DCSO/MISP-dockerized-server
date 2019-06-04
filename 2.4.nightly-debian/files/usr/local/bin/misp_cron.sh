#!/bin/bash
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[ENTRYPOINT_CRON] [ $COUNTER ] ${NC}"
COUNTER="$(date +%Y-%m-%d_%H:%M)"

# Functions
echo (){
    command echo -e "$STARTMSG $*"
}

# Environment Parameter
    CAKE=${CAKE:-"$PATH_TO_MISP/Console/cake"}
    INTERVAL=${1:-'3600'}   # Default 3600 seconds
    USER_ID=${2:-'1'}       # Default user id 1 admin@admin.test


#
#   MAIN
#

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

    # Pull: MISP/app/Console/cake Server pull [user_id] [server_id] [full|update]
    echo "$CAKE Server pull $USER_ID..." && $CAKE Server pull "$USER_ID"

    # Push: MISP/app/Console/cake Server push [user_id] [server_id]
    echo "$CAKE Server push $USER_ID..." && $CAKE Server push "$USER_ID"

    # CacheFeed: MISP/app/Console/cake Server cacheFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$CAKE Server cacheFeed $USER_ID all..." && $CAKE Server cacheFeed "$USER_ID" all

    #FetchFeed: MISP/app/Console/cake Server fetchFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$CAKE Server fetchFeed $USER_ID all..." && $CAKE Server fetchFeed "$USER_ID" all
    
    # End Message
    echo "Finished MISP-dockerized Cronjob at $(date +%Y-%m-%d_%H:%M) and wait $INTERVAL seconds... "
    
    # Wait this time
    sleep "$INTERVAL"
done