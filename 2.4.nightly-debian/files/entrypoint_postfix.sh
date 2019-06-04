#!/bin/bash
set -eu


NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[ENTRYPOINT_POSTFIX]${NC}"
echo (){
    command echo -e "$STARTMSG $*"
}

[ "$MAIL_ENABLE" = "no" ] && echo "Mail should be disabled." && sleep 3600

# Variables
  POSTFIX_PATH="/etc/postfix"
  POSTFIX_CONFIG="$POSTFIX_PATH/main.cf"
  POSTFIX_SMTP_AUTH="$POSTFIX_PATH/smtp_auth"
  POSTFIX_GENERIC="$POSTFIX_PATH/generic"
  POSTFIX_SENDER_CANONICAL="$POSTFIX_PATH/sender_canonical"

# Environment Parameter
  # POSTFIX_HOSTNAME for the Mailserver
  [ -z "$MISP_FQDN" ] && MISP_FQDN="misp.example.com"
  # POSTFIX_DOMAIN for Outgoing Mail
  [ -z "$MAIL_DOMAIN" ] && MAIL_DOMAIN="example.com"
  # Sender for local postfix outgoing Mails
  [ -z "$MAIL_SENDER_ADDRESS" ] && MAIL_SENDER_ADDRESS="admin@example.com"
  # Relahost to Send Mails
  [ -z "$MAIL_RELAYHOST" ] && MAIL_RELAYHOST="smtp.example.local:587"
  # RELAY User and Password
  [ -z "$MAIL_RELAY_USER" ] && MAIL_RELAY_USER=""
  [ -z "$MAIL_RELAY_PASSWORD" ] && MAIL_RELAY_PASSWORD=""
  # Allow only MISP Docker Container Access
  [ -z "$DOCKER_NETWORK" ] && DOCKER_NETWORK="192.168.47.0/28"
  # You need to get more postfix output for a specified host normally the POSTFIX_RELAYHOST or misp-server
  [ -z "$MAIL_DEBUG_PEERS" ] && MAIL_DEBUG_PEERS="none"

# Set Environment Variables in POSTFIX_CONFIG
  postconf myhostname="$MISP_FQDN"
# POSTFIX_DOMAIN for Outgoing Mail
  postconf mydomain="$MAIL_DOMAIN"
# Relahost to Send Mails
  postconf POSTFIX_RELAYHOST="$MAIL_RELAYHOST"
# Allow only MISP Docker Container Access
  postconf mynetworks="127.0.0.1/32 [::1]/128 $DOCKER_NETWORK"
# If you need to get more postfix output for a specified host normally the POSTFIX_RELAYHOST or misp-server
  # if MAIL_DEBUG_PEERS isn't none set debug peer:
  if [ "$MAIL_QUESTION_DEBUG_PEERS" = "yes" ]
  then
    [ "$MAIL_DEBUG_PEERS" != "none" ] && postconf debug_peer_list="$MAIL_DEBUG_PEERS"
  fi

# Sender for local postfix outgoing Mails
echo "root $MAIL_SENDER_ADDRESS" > "$POSTFIX_GENERIC"
postmap $POSTFIX_GENERIC

echo "@$MAIL_DOMAIN $MAIL_SENDER_ADDRESS" > "$POSTFIX_SENDER_CANONICAL"
postmap "$POSTFIX_SENDER_CANONICAL"

# RELAY User and Password
echo -e "$MAIL_RELAYHOST $MAIL_RELAY_USER:$MAIL_RELAY_PASSWORD" > $POSTFIX_SMTP_AUTH
postmap $POSTFIX_SMTP_AUTH

# Check Postfix configuration
myCMD="postconf -c /etc/postfix/"

if [[ $myCMD != 0 ]]; then
  echo "Postfix configuration error, refusing to start."
  exit 1
else
  echo "Start Postfix and sleep..."
  # Start Postfix
  /usr/lib/postfix/sbin/post-install meta_directory=/etc/postfix create-missing
  /usr/lib/postfix/sbin/master
  postfix -c /etc/postfix/ start
  # wait a long time...
  sleep 126144000
fi
