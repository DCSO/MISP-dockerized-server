#!/bin/bash
STARTMSG="[build]"

[ -z "$1" ] && echo "$STARTMSG No parameter with the image version. Exit now." && exit 1
[ "$1" == "dev" ] && echo "$STARTMSG False first argument. Abort." && exit 1

VERSION="$1"
if [[ "$2" == "true" ]]; then ENVIRONMENT="prod"; fi;


#################   MANUAL VARIABLES #################
# path of the script
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
# dockerfile name:
DOCKERFILE_NAME=Dockerfile
# Which Folder the script should use

echo "$STARTMSG Index all versions..."
if [ -z $1 ] ;then
    	# build all you find
        FOLDER=( */)
        FOLDER=( "${FOLDER[@]%/}" )
else
    # build only the argumented one
    FOLDER="$VERSION"
fi
#########################################################

#################   AUTOMATIC VARIABLES #################
# Find Out Git Hub Repository
echo "$STARTMSG Set GIT_REPO..."
if [ ! -z "$(git remote get-url origin|grep git@)" ]
then
    GIT_REPO="$(git remote get-url origin|sed 's,.*:,,'|sed 's,....$,,')"
elif [ ! -z "$(git remote get-url origin|grep http)" ] 
then    
    GIT_REPO="$(git remote get-url origin|sed 's,http.*//.*/,,'|sed 's,....$,,')"
elif [ ! -z "$(echo "$GIT_REPO"|grep "$GITLAB_HOST")" ] 
then
    GIT_REPO="$(git remote get-url origin|sed 's,.*'${GITLAB_HOST}'/'${GITLAB_GROUP}'/,,'|sed 's,....$,,')"
else
    echo "Can not found the Git URL. Exit now."
    exit 1
fi

GIT_REPO_URL="https://github.com/$GIT_REPO"
# Dockerifle Settings
CONTAINER_NAME="$(echo "$GIT_REPO"|cut -d / -f 2|tr '[:upper:]' '[:lower:]')"
DOCKER_REPO="not2push/$CONTAINER_NAME"
#########################################################

echo "$STARTMSG Start image building..."
for FOLD in ${FOLDER[@]}
do  
    # Find Out Version from folder
    VERSION=$(echo $FOLD|cut -d- -f 1)
    DOCKERFILE_PATH="$SCRIPTPATH/../$FOLD"
    # Load Variables from configuration file
    source "$DOCKERFILE_PATH/configuration.sh"
    # Default mode add "-dev" tag.
    if [ "$ENVIRONMENT" == "prod" ]
    then
        # PROD Version
        TAGS="-t $DOCKER_REPO:$FOLD"
    else
        # DEV Version
        TAGS="-t $DOCKER_REPO:$FOLD-dev"
    fi
    
    # Default build args
    BUILD_ARGS+="
        --build-arg BUILD_DATE="$(date -u +"%Y-%m-%d")" \
        --build-arg NAME="$CONTAINER_NAME" \
        --build-arg GIT_REPO="$GIT_REPO_URL" \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg VERSION="$VERSION" \
    "
    # build image
    docker build \
            $BUILD_ARGS \
        -f "$DOCKERFILE_PATH/$DOCKERFILE_NAME" $TAGS "$DOCKERFILE_PATH"/
done

echo "$STARTMSG $0 is finished."
