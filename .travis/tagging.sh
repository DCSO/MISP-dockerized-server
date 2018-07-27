#!/bin/bash
# Set an option to exit immediately if any error appears
set -xe

echo  "### Show Images before Tagging:"
docker images

# Docker Repo e.g. dcso/misp-dockerized-proxy
[ -z "$(git remote get-url origin|grep git@)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
[ -z "$(git remote get-url origin|grep http)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*github.com/,,'|sed 's,....$,,')"
[ -z "$GITLAB_HOST" ] || [ -z "$(echo $GIT_REPO|grep $GITLAB_HOST)" ] ||  GIT_REPO="$(git remote get-url origin|sed 's,.*'${GITLAB_HOST}'/'${GITLAB_GROUP}'/,,'|sed 's,....$,,')"

CONTAINER_NAME="$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

[ -z "$INTERNAL_REGISTRY_HOST" ] && DOCKER_REPO="dcso/$CONTAINER_NAME"
[ -z "$INTERNAL_REGISTRY_HOST" ] || DOCKER_REPO="$INTERNAL_REGISTRY_HOST/$CONTAINER_NAME"

# Create the Array
FOLDER_ARRAY=( */)
FOLDER_ARRAY=( "${FOLDER_ARRAY[@]%/}" )
# How many items in your Array:
index=${#FOLDER_ARRAY[@]}       

# SORT ARRAY
IFS=$'\n' 
    sorted=($(sort <<<"${FOLDER_ARRAY[*]}"))
unset IFS

# Latest Version
LATEST=$(echo ${sorted[$index-1]}|cut -d- -f 1)

# Lookup to all build versions of the current docker container
ALL_BUILD_DOCKER_VERSIONS=$(docker images --format '{{.Repository}}={{.Tag}}'|grep $DOCKER_REPO|cut -d = -f 2)



# Tag Latest + Version Number
for i in $ALL_BUILD_DOCKER_VERSIONS
do
    VERSION=$(echo $i|cut -d- -f 1)
    BASE=$(echo $i|cut -d- -f 2)
    # CHECK Alpine Image
    if [ $BASE == "alpine" ] ;then
        #If avaialble tag always alpine as latest
        [ $VERSION == $LATEST ] && docker tag $DOCKER_REPO:$i $DOCKER_REPO:latest-dev
        # docker tag $DOCKER_REPO:$i $DOCKER_REPO:$VERSION-dev
    else if [ $BASE == "ubuntu" -a ! -d "$VERSION-alpine" ] ;then
        # If no alpine and debian available tag ubuntu
        [ $VERSION == $LATEST ] && docker tag $DOCKER_REPO:$i $DOCKER_REPO:latest-dev
        #docker tag $DOCKER_REPO:$i $DOCKER_REPO:$VERSION-dev
        fi
    fi
done

echo  "### Show Images after Tagging:"
docker images
