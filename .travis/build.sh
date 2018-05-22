#!/bin/bash
# Set an option to exit immediately if any error appears
set -xe

#################   MANUAL VARIABLES #################
# path of the script
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
# dockerfile name:
DOCKERFILE_NAME=Dockerfile
# Which Folder the script should use
[ "$1" == "dev" ] && echo "false first argument. Abort." && exit 1
if [ -z $1 ] ;then
    	# build all you find
        FOLDER=( */)
        FOLDER=( "${FOLDER[@]%/}" )
else
    # build only the argumented one
    FOLDER=$1
fi
#########################################################

#################   AUTOMATIC VARIABLES #################
# Find Out Git Hub Repository
[ -z "$(git remote get-url origin|grep git@)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
[ -z "$(git remote get-url origin|grep http)" ] || GIT_REPO="$(git remote get-url origin|sed 's,.*github.com/,,'|sed 's,....$,,')"
GIT_REPO_URL="https://github.com/$GIT_REPO"
# Dockerifle Settings
CONTAINER_NAME="$(echo $GIT_REPO|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"
DOCKER_REPO="dcso/$CONTAINER_NAME"
#########################################################

for FOLD in ${FOLDER[@]}
do  
    #Find Out Version from folder
    VERSION=$(echo $FOLD|cut -d- -f 1)
    DOCKERFILE_PATH="$SCRIPTPATH/../$FOLD"
    # load Variables from configuration file
    source $DOCKERFILE_PATH/configuration.sh
    ### Add -dev to tag if dev is set as a second argument
    [ "$2" == "prod" ] || TAGS="-t $DOCKER_REPO:$FOLD-dev"
    [ "$2" == "prod" ] && TAGS="-t $DOCKER_REPO:$FOLD"

    # Default Build Args
    BUILD_ARGS+="
        --build-arg RELEASE_DATE="$(date +"%Y-%m-%d")" \
        --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --build-arg NAME="$CONTAINER_NAME" \
        --build-arg GIT_REPO="$GIT_REPO_URL" \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg VERSION="$VERSION" \
    "
    # build container
    docker build \
            $BUILD_ARGS \
        -f $DOCKERFILE_PATH/$DOCKERFILE_NAME $TAGS $DOCKERFILE_PATH/
done
