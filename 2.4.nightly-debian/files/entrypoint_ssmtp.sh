#!/bin/bash
# Support for the script:
# - https://github.com/philoles/docker-ssmtp/blob/master/0.1/ssmtp_custom.conf
# - https://unix.stackexchange.com/questions/36982/can-i-set-up-system-mail-to-use-an-external-smtp-server
# - https://stackoverflow.com/questions/6573511/how-do-i-specify-to-php-that-mail-should-be-sent-using-an-external-mail-server
# - https://wiki.debian.org/sSMTP
set -eu

# Variables
conf='/etc/ssmtp/ssmtp.conf'
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[ENTRYPOINT_SSMTP]${NC}"

# Functions
echo (){
    command echo -e "$STARTMSG $*"
}

# Check if Mail should be disabled.
[ "$MAIL_ENABLE" = "no" ] && echo "Mail should be disabled." && sleep 3600


# Environment Parameter
  MISP_FQDN=${MISP_FQDN:-'misp-dockerized-server'}
  MAIL_DOMAIN=${MAIL_DOMAIN:-'example.com'}
  MAIL_SENDER_ADDRESS=${MAIL_SENDER_ADDRESS:-'MISP-dockerized@example.com'}
  MAIL_RELAYHOST=${MAIL_RELAYHOST:-'misp-postfix'}
  UseTLS=${MAIL_TLS:-'NO'}
  UseSTARTTLS=${MAIL_TLS:-'NO'}



# Save Original Configuration
[ ! -f "$conf.bak" ] && cp $conf $conf.bak

# Rewrite Configuration
cat > $conf << EOF

#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
# root=postmaster@gdata.com
root=$MAIL_SENDER_ADDRESS

# The place where the mail goes. The actual machine name is required no 
# MX records are consulted. Commonly mailhosts are named mail.domain.com
mailhub=$MAIL_RELAYHOST
AuthUser=$MAIL_RELAY_USER
AuthPass=$MAIL_RELAY_PASSWORD
UseTLS=$UseTLS
UseSTARTTLS=$UseSTARTTLS

# Where will the mail seem to come from?
# rewriteDomain=
rewriteDomain=$MAIL_DOMAIN

# The full hostname
# hostname=gdata
hostname=$MISP_FQDN

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
#FromLineOverride=YES

EOF

# Post Tasks
  # Change Owner
chown root:mail /etc/ssmtp/ssmtp.conf
  # Change file permissions
chmod 640 /etc/ssmtp/ssmtp.conf
  # Add User www-data to group mail
usermod -a -G mail www-data
