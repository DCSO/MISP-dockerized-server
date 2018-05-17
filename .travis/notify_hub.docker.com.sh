#!/bin/bash

# Docker Repo e.g. dcso/misp-dockerized-proxy
GIT_REPO="$(git remote get-url origin|sed 's/.*://'|sed 's/....$//')"
DOCKER_REPO="dcso/$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

curl -X POST -H "Content-Type: application/json"  --data '{"docker_tag_name": "hub_automatic_untested"}'  https://registry.hub.docker.com/u/$DOCKER_REPO/trigger/$1/