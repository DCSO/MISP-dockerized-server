#!/bin/sh
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[CHANGE_PGP]${NC}"

GPG_HOME=${GPG_HOME:-"/var/www/.gnupg"}

GPG_PUBLIC="public.key"
GPG_PRIVATE="private.key"

# Functions
echo (){
    command echo "$STARTMSG $*"
}

# Environment Parameter
    #




#
#   MAIN
#

# Import all .asc files
if [ -f "$GPG_HOME/*.asc" ];then
    for i in $GPG_HOME/*.asc
    do
        $SUDO_WWW gpg --import "$i"
    done
fi


