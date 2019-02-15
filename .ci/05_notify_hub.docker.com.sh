#!/bin/bash
STARTMSG="[notify_hob.docker.com]"

NOTIFY_URL="$1"

echo "$STARTMSG Notify hub.docker.com"

curl -X POST -H "Content-Type: application/json"  --data '{"docker_tag_name": "hub_automatic_untested"}'  "$NOTIFY_URL"

echo "$STARTMSG $0 is finished."
