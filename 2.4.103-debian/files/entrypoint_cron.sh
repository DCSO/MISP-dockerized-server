#!/bin/sh
set -e

STARTMSG="[ENTRYPOINT_CRON]"

if [ -z "$CRON_INTERVAL" ]; then
    # If CRON_INTERVAL is not set, deactivate it.
    echo "$STARTMSG Deactivate cron job."
    exit
elif [ "$CRON_INTERVAL" = 0 ]; then
    echo "$STARTMSG Deactivate cron job."
    exit
else
    INTERVAL="$CRON_INTERVAL"
    # wait for the first round
    echo "$STARTMSG Wait $INTERVAL seconds, then start the first intervall." && sleep "$INTERVAL" 
    # start cron job
    echo "$STARTMSG Start cron job" && misp_cron.sh "$INTERVAL"
fi

