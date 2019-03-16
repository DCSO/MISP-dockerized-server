#!/bin/bash
set -e

STARTMSG="[ENTRYPOINT_CRON]"

if [ -z "$CRON_INTERVAL" ]; then
    # If CRON_INTERVAL is not set, decativate it.
    echo "$STARTMSG Deactivate cron job."
    wait
else
    INTERVAL="$CRON_INTERVAL"
fi

# start cron job
echo "$STARTMSG Wait $INTERVAL seconds, then start the first intervall." && sleep "$INTERVAL" 

echo "$STARTMSG Start cron job" && misp_cron.sh "$INTERVAL"