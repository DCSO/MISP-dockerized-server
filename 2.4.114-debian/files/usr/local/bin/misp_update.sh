#!/bin/bash
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[UPDATE_MISP]${NC}"

# Functions
echo (){
    command echo -e "$STARTMSG $*"
}

# Environment Parameter
    CAKE=${CAKE:-"$PATH_TO_MISP/Console/cake"}

#
#   MAIN
#

# Update the galaxies…
echo "$STARTMSG Update Galaxies..." && "$CAKE" Admin updateGalaxies
# Updating the taxonomies…
echo "$STARTMSG Update Taxonomies..." && "$CAKE" Admin updateTaxonomies
# Updating the warning lists…
echo "$STARTMSG Update WarningLists..." && "$CAKE" Admin updateWarningLists
# Updating the notice lists…
echo "$STARTMSG Update NoticeLists..." && "$CAKE" Admin updateNoticeLists
    #curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST https://127.0.0.1/noticelists/update
# Updating the object templates…
echo "$STARTMSG Update Object Templates..." && "$CAKE" Admin updateObjectTemplates
#curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST https://127.0.0.1/objectTemplates/update

exit 0