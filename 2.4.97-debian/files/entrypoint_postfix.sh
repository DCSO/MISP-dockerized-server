#!/bin/bash
set -e

POSTFIX_PATH="/etc/postfix"
POSTFIX_CONFIG="$POSTFIX_PATH/main.cf"
SMTP_AUTH="$POSTFIX_PATH/smtp_auth"
GENERIC="$POSTFIX_PATH/generic_misp"

function mysed() {
    source=$1
    target=$2
    file=$3
    [ "$#" = "2" ] && file=$2 && target=''
    # This fu nction replace the Keywords ($1) with the content of environment variable ($2) in the file ($3)
    sed -i 's,{'$source'},'$target',g' $file
}

# Set Environment Variables in Config
mysed HOSTNAME $HOSTNAME $POSTFIX_CONFIG
# Domain for Outgoing Mail
mysed DOMAIN $DOMAIN $POSTFIX_CONFIG
# Sender for local postfix outgoing Mails
mysed SENDER_ADDRESS $SENDER_ADDRESS $GENERIC
# Relahost to Send Mails
mysed RELAYHOST $RELAYHOST $POSTFIX_CONFIG
mysed RELAYHOST $RELAYHOST $SMTP_AUTH
# RELAY User and Password
mysed RELAY_USER $RELAY_USER $SMTP_AUTH
mysed RELAY_PASSWORD $RELAY_PASSWORD $SMTP_AUTH
# Allow only MISP Docker Container Access
mysed DOCKER_NETWORK $DOCKER_NETWORK $POSTFIX_CONFIG
# If you need to get more postfix output for a specified host normally the relayhost or misp-server
  # if DEBUG_PEER isn't none set debug peer:
  [ "$DEBUG_PEER" == "none" ] || mysed DEBUG_PEER $DEBUG_PEER $POSTFIX_CONFIG
  # if DEBUG_PEER IS none delete it:
  [ "$DEBUG_PEER" == "none" ] && mysed DEBUG_PEER $POSTFIX_CONFIG


# Start Postfix
postmap $SMTP_AUTH
postmap $GENERIC
/usr/lib/postfix/sbin/post-install meta_directory=/etc/postfix create-missing
/usr/lib/postfix/sbin/master


# Check Postfix configuration
postconf -c /etc/postfix/

if [[ $? != 0 ]]; then
  echo "Postfix configuration error, refusing to start."
  exit 1
else
  postfix -c /etc/postfix/ start
  sleep 126144000
fi