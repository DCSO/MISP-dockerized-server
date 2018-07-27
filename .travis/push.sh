#!/bin/bash
# Set an option to exit immediately if any error appears
set -xe

# Docker Repo e.g. dcso/misp-dockerized-proxy
[ -z "$(git remote get-url origin|grep git@)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
[ -z "$(git remote get-url origin|grep http)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*github.com/,,'|sed 's,....$,,')"
[ -z "$(echo $GIT_REPO|grep $GITLAB_HOST)" ] ||  GIT_REPO="$(git remote get-url origin|sed 's,.*'${GITLAB_HOST}'/'${GITLAB_GROUP}'/,,'|sed 's,....$,,')"

CONTAINER_NAME="$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

[ -z "$INTERNAL_REGISTRY_HOST" ] && DOCKER_REPO="dcso/$CONTAINER_NAME"
[ -z "$INTERNAL_REGISTRY_HOST" ] || DOCKER_REPO="$INTERNAL_REGISTRY_HOST/$CONTAINER_NAME"


# Lookup to all build versions of the current docker container
ALL_BUILD_DOCKER_VERSIONS=$(docker images --format '{{.Repository}}={{.Tag}}'|grep $DOCKER_REPO|cut -d = -f 2)



for i in $ALL_BUILD_DOCKER_VERSIONS
do
    docker push $DOCKER_REPO:$i
done