#!/bin/bash

# Docker Repo e.g. dcso/misp-dockerized-proxy
GIT_REPO="$(git remote get-url origin|sed 's/.*://'|sed 's/....$//')"
DOCKER_REPO="dcso/$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

# Lookup to all build versions of the current docker container
ALL_BUILD_DOCKER_VERSIONS=$(docker images --format '{{.Repository}}={{.Tag}}'|grep $DOCKER_REPO|cut -d = -f 2)

for i in $ALL_BUILD_DOCKER_VERSIONS
do
    docker push $DOCKER_REPO:$i
done