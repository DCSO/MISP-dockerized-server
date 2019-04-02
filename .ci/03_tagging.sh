#!/bin/bash
set -e
STARTMSG="[tagging]"

[ -z "$1" ] && echo "$STARTMSG No parameter with the image version. Exit now." && exit 1
[ "$1" == "true" ] && echo "$STARTMSG False first argument. Abort." && exit 1

REGISTRY_URL="$1"
if [[ "$2" == "true" ]]; then ENVIRONMENT="prod"; fi;

# change directory to the top level:
pushd ..

# Docker Repo e.g. dcso/misp-dockerized-proxy
[ -z "$(git remote get-url origin|grep git@)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
[ -z "$(git remote get-url origin|grep http)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*github.com/,,'|sed 's,....$,,')"
[ -z "$GITLAB_HOST" ] || [ -z "$(echo "$GIT_REPO"|grep "$GITLAB_HOST")" ] ||  GIT_REPO="$(git remote get-url origin|sed 's,.*'${GITLAB_HOST}'/'${GITLAB_GROUP}'/,,'|sed 's,....$,,')"

# Set Container Name
CONTAINER_NAME="$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"

# Show Images before tagging
echo  "$STARTMSG ### Show images before tagging:"
docker images | grep "$CONTAINER_NAME"

# Set Docker Repository
DOCKER_REPO="$REGISTRY_URL/$CONTAINER_NAME"
SOURCE_REPO="not2push"

# Search the latest image
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

# Search the current major version
    # All Latest Major versions
    MAJOR_LATEST=""
    # Run over all FOLDER versions and add all first digit numbers
    for i in ${sorted[@]}
    do
        # change from 1.0-ubuntu -> 1
        CURRENT_MAJOR_VERSION="$(echo "$i"|cut -d . -f 1)"
        CURRENT_MINOR_VERSION="$(echo "$i"|cut -d . -f 2|cut -d - -f 1)"

        # Check if there is any Version available for the current MAJOR version:
        [ -z ${MAJOR_LATEST[$CURRENT_MAJOR_LATEST]} ] && MAJOR_LATEST[$CURRENT_MAJOR_VERSION]=$i && continue

        # change the Folder Name which are written into the Array on position of the current_major_version from 1.0-ubuntu to 1
        LIST_MINOR_VERSION=$(echo ${MAJOR_LATEST[$CURRENT_MAJOR_VERSION]}|cut -d . -f 2|cut -d - -f 1)
        # Check if the current minor digit from Elelement i is higher than the one which are saved in the array
        [[ $LIST_MINOR_VERSION < $CURRENT_MINOR_VERSION ]] && MAJOR_LATEST[$CURRENT_MAJOR_VERSION]=$i && continue
    done


# Lookup to all build versions of the current docker container
ALL_BUILD_DOCKER_VERSIONS=$(docker images --format '{{.Repository}}={{.Tag}}'|grep $CONTAINER_NAME |cut -d = -f 2)

# Tag Latest + Version Number
for i in $ALL_BUILD_DOCKER_VERSIONS
do
    VERSION=$(echo "$i"|cut -d- -f 1)                 # for example 1.0
    BASE=$(echo "$i"|cut -d- -f 2)                    # for example ubuntu
    CURRENT_MAJOR_VERSION="$(echo "$i"|cut -d . -f 1)"        # for example 1

    # Remove '-dev' tag
    if [ "$ENVIRONMENT" == "prod" ]; then
        #
        #   If prod=true, ~ prodcutin ready image
        #

        # Add custom Docker registry tag
        docker tag "$SOURCE_REPO/$CONTAINER_NAME:$i" "$DOCKER_REPO:$VERSION-$BASE"

        # Add latest tag
        if [ "$VERSION" == "$LATEST" ]; then
            docker tag "$SOURCE_REPO/$CONTAINER_NAME:$i" "$DOCKER_REPO":latest
        fi

        # Add latest Major Version Tag
        for k in ${MAJOR_LATEST[@]}
        do
            #CURRENT_MAJOR_VERSION="$(echo $k|cut -d . -f 1)"
            [ "$i" == "$k-dev" ] && docker tag "$SOURCE_REPO/$CONTAINER_NAME:$i" "$DOCKER_REPO:$CURRENT_MAJOR_VERSION"
        done
    else
        #
        #   Add '-dev' tag
        #   
    
        # Add custom Docker registry tag
        docker tag "$SOURCE_REPO/$CONTAINER_NAME:$i" "$DOCKER_REPO:$VERSION-$BASE-dev"
        
        # Add latest tag
        if [ "$VERSION" == "$LATEST" ]; then
            docker tag "$SOURCE_REPO/$CONTAINER_NAME:$i" "$DOCKER_REPO:latest-dev"
        fi

        # Add latest Major Version Tag
        for k in ${MAJOR_LATEST[@]}
        do
            CURRENT_MAJOR_VERSION="$(echo "$k"|cut -d . -f 1)"
            [ "$i" == "$k-dev" ] && docker tag "$SOURCE_REPO/$CONTAINER_NAME:$i" "$DOCKER_REPO:$CURRENT_MAJOR_VERSION-dev"
        done
    fi
done

echo  "$STARTMSG ### Show images after tagging:"
docker images | grep "$DOCKER_REPO"

echo "$STARTMSG $0 is finished."

