#!/bin/bash
set -e


NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

STARTMSG="${Light_Green}[ENTRYPOINT_POSTFIX]${NC}"


POSTFIX_PATH="/etc/postfix"
POSTFIX_CONFIG="$POSTFIX_PATH/main.cf"
SMTP_AUTH="$POSTFIX_PATH/smtp_auth"
GENERIC="$POSTFIX_PATH/generic_misp"

# Set Environment Variables in Config
  postconf myhostname="$HOSTNAME"
# Domain for Outgoing Mail
  postconf mydomain="$DOMAIN"
# Relahost to Send Mails
  postconf relayhost="$RELAYHOST"
# Allow only MISP Docker Container Access
  postconf mynetworks="127.0.0.1/32 [::1]/128 $DOCKER_NETWORK"
# If you need to get more postfix output for a specified host normally the relayhost or misp-server
  # if DEBUG_PEER isn't none set debug peer:
  [ "$DEBUG_PEER" == "none" ] || postconf debug_peer_list="$DEBUG_PEER"


# Sender for local postfix outgoing Mails
#mysed SENDER_ADDRESS $SENDER_ADDRESS $GENERIC
echo "root $SENDER_ADDRESS" > $GENERIC
echo "@$DOMAIN $SENDER_ADDRESS" >> $GENERIC


# RELAY User and Password
echo -e "$RELAYHOST $RELAY_USER:$RELAY_PASSWORD" > $SMTP_AUTH

# Make sure permissions are ok
chown -R root:root /etc/postfix/*

# Start Postfix
postmap $SMTP_AUTH
postmap $GENERIC
/usr/lib/postfix/sbin/post-install meta_directory=/etc/postfix create-missing
/usr/lib/postfix/sbin/master


# Check Postfix configuration
postconf -c /etc/postfix/

if [[ $? != 0 ]]; then
  echo "$STARTMSG GPostfix configuration error, refusing to start."
  exit 1
else
  echo "$STARTMSG Start Postfix..." && postfix -c /etc/postfix/ start
  sleep 126144000
fi
