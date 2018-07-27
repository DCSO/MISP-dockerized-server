#!/bin/bash
# Set an option to exit immediately if any error appears
set -xe

# Docker Repo e.g. dcso/misp-dockerized-proxy
[ -z "$(git remote get-url origin|grep git@)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
[ -z "$(git remote get-url origin|grep http)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*github.com/,,'|sed 's,....$,,')"
[ -z "$(echo $GIT_REPO|grep $GITLAB_HOST)" ] ||  GIT_REPO="$(git remote get-url origin|sed 's,.*'${GITLAB_HOST}'/'${GITLAB_GROUP}'/,,'|sed 's,....$,,')"

DOCKER_REPO="dcso/$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

curl -X POST -H "Content-Type: application/json"  --data '{"docker_tag_name": "hub_automatic_untested"}'  https://registry.hub.docker.com/u/$DOCKER_REPO/trigger/$1/