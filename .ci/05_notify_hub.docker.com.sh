#!/bin/bash
STARTMSG="[notify_hob.docker.com]"

DOCKER_SLUG="$1"
TOKEN="$2"

echo "$STARTMSG Notify hub.docker.com"

# Find Out Git Hub Repository
echo "$STARTMSG Set GIT_REPO..."
if [ ! -z "$(git remote get-url origin|grep git@)" ]
then
    GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
elif [ ! -z "$(git remote get-url origin|grep http)" ] 
then    
    GIT_REPO="$(git remote get-url origin|sed 's,http.*//.*/,,'|sed 's,....$,,')"
elif [ ! -z "$(echo $GIT_REPO|grep $GITLAB_HOST)" ] 
then
    GIT_REPO="$(git remote get-url origin|sed 's,.*'${GITLAB_HOST}'/'${GITLAB_GROUP}'/,,'|sed 's,....$,,')"
else
    echo "Can not found the Git URL. Exit now."
    exit 1
fi


DOCKER_REPO="$DOCKER_SLUG/$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

curl -X POST -H "Content-Type: application/json"  --data '{"docker_tag_name": "hub_automatic_untested"}'  https://registry.hub.docker.com/u/$DOCKER_REPO/trigger/$TOKEN/

echo "$STARTMSG $0 is finished."
