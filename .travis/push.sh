#!/bin/bash
# Set an option to exit immediately if any error appears
set -xe

# Docker Repo e.g. dcso/misp-dockerized-proxy
[ -z "$(git remote get-url origin|grep git@)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
[ -z "$(git remote get-url origin|grep http)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*github.com/,,'|sed 's,....$,,')"
DOCKER_REPO="dcso/$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

# Lookup to all build versions of the current docker container
ALL_BUILD_DOCKER_VERSIONS=$(docker images --format '{{.Repository}}={{.Tag}}'|grep $DOCKER_REPO|cut -d = -f 2)

for i in $ALL_BUILD_DOCKER_VERSIONS
do
    docker push $DOCKER_REPO:$i
done