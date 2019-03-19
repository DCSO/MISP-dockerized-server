#!/bin/bash

set -e

STARTMSG="[ENTRYPOINT_CRON]"
CAKE="/var/www/MISP/app/Console/cake"



# SLEEP 1h
sleep 3600

[ -z $AUTH_KEY ] && export AUTH_KEY=$(mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2|tail -1)

# Wait until database is ready then test    
while(true)
do
    [ -z "$(mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -e 'select 1;'|tail -1|grep ERROR)" ] && [ ! -z "$($CAKE Admin getSetting MISP.baseurl|grep value)" ] && break;
    sleep 3
done

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

while(true)
do
    # START the SCRIPT
    COUNTER="`date +%Y-%m-%d_%H:%M`"
    echo "$STARTMSG [ $COUNTER ] Start MISP-dockerized Cronjob at `date +%Y-%m-%d_%H:%M`... "


    #If you would like to automate tasks such as caching feeds or pulling from server instances, you can do it using the following command line tools. Simply execute the given commands via the command line / create cron jobs easily out of them.:
    #Pull: MISP/app/Console/cake Server pull [user_id] [server_id] [full|update]

    echo "$STARTMSG $CAKE Server pull 1 update..." && $CAKE Server pull 1 update

    # CacheFeed: MISP/app/Console/cake Server cacheFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$STARTMSG $CAKE Server cacheFeed 1 all..." && $CAKE Server cacheFeed 1 all

    #FetchFeed: MISP/app/Console/cake Server fetchFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$STARTMSG $CAKE Server fetchFeed 1 all..." && $CAKE Server fetchFeed 1 all
    # Finished
    echo "$STARTMSG [ $COUNTER ] Finished MISP-dockerized Cronjob at `date +%Y-%m-%d_%H:%M`... "
    sleep 3600
done