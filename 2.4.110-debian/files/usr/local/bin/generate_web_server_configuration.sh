#!/bin/sh
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[GENERATE_WEB_SERVER_CONFIGURATION]${NC}"
# Webserver Configuration
HTTP_CONF_DIRECTORY="/etc/apache2/sites-enabled"
HTTPS_FILE="${HTTP_CONF_DIRECTORY}/misp.ssl.conf"
HTTP_FILE="${HTTP_CONF_DIRECTORY}/misp.conf"
SERVER_STATUS_FILE="${HTTP_CONF_DIRECTORY}/server-status.conf"
PORTS_FILE="/etc/apache2/ports.conf"
SSL_CERT="/etc/apache2/ssl/cert.pem"
SSL_KEY="/etc/apache2/ssl/key.pem"
SSL_CA="/etc/apache2/ssl/ca.pem"
SSL_DH_FILE="/etc/apache2/ssl/dhparams.pem"
SSL_PASSPHRASE_FILE="/etc/apache2/ssl/ssl.passphrase"
SSL_PASSPHRASE_APACHE2_FILE="/etc/apache2/ssl/ssl-apache-dialog.sh"
USE_SSL_CA=""
USE_SSL_PASSPHRASE_FILE=""


MAIL_CONTACT_ADDRESS=${MAIL_CONTACT_ADDRESS:-"no-reply@$MISP_FQDN"}
MISP_FQDN=${MISP_FQDN:-"misp-server"}



CONFIG_PART_FOR_HTTP_HTTPS="
    ServerAdmin ${MAIL_CONTACT_ADDRESS}
    ServerName ${MISP_FQDN}
    ServerAlias misp-server 127.0.0.1
    
    DocumentRoot /var/www/MISP/app/webroot
    
    <Directory /var/www/MISP/app/webroot>
        Options -Indexes
        AllowOverride all
        Order allow,deny
        allow from all
    </Directory>

    LogLevel warn

    # We have installed rsyslog which take the files and sends it to Docker stdout and stderr
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

    ServerSignature Off
    # Header set X-Content-Type-Options nosniff
    # Header set X-Frame-Options DENY
"


# Functions
echo (){
    command echo "$STARTMSG $*"
}

create_dh(){
    echo "Create DH params - This can take a long time, so take a break and enjoy a cup of tea or coffee."
    openssl dhparam -out "$SSL_DH_FILE" 2048 
}

# Environment Parameter
    #
    # SSL
    SSL_PASSPHRASE=${SSL_PASSPHRASE:-}
    SSL_PASSPHRASE_ENABLE=${SSL_PASSPHRASE_ENABLE:-"no"}



#
#   MAIN
#
echo "... Webserver configuration generation..."

# Check if Directory exists
[ -d "$HTTP_CONF_DIRECTORY" ] && mkdir -p "$HTTP_CONF_DIRECTORY"
# Check if SSL CA File exists
[ -f "$SSL_CA" ] && USE_SSL_CA="SSLCertificateChainFile ${SSL_CA}"
# Check if DH File exist, if not create one
[ ! -f "$SSL_DH_FILE" ] && create_dh

# Checkl if SSL Cert and Private Key Files exists
if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]
then

    if [ "$SSL_PASSPHRASE_ENABLE" = "yes" ]
    then
        if [ -n "$SSL_PASSPHRASE" ]
        then
            echo "Copy environment variable into file..."
            command echo "$SSL_PASSPHRASE" > "$SSL_PASSPHRASE_FILE"
            echo "Copy environment variable into file...finished"
        else
            echo "... ... No Environment variable exists will try passphrase file..."
            if [ ! -f "$SSL_PASSPHRASE_FILE" ] 
            then 
                echo "... ... No passphrase file found: $SSL_PASSPHRASE_FILE"
                echo "... ... Please add your file in config/ssl/"
                echo "... ... For more information please go to: https://dcso.github.io/MISP-dockerized-docs/admin/ssl_passphrase.html"
                exit 1
            fi
        fi

        # Set variable to write it into web server configuration
        USE_SSL_PASSPHRASE_FILE="SSLPassPhraseDialog exec:$SSL_PASSPHRASE_APACHE2_FILE"

        # create Apache2 file:
        SSL_PASSPHRASE_FILE_CONTENT="
            #!/bin/sh
            cat $SSL_PASSPHRASE_FILE
            "
        command echo "$SSL_PASSPHRASE_FILE_CONTENT" > "$SSL_PASSPHRASE_APACHE2_FILE"
        chmod +x "$SSL_PASSPHRASE_APACHE2_FILE"
        
        echo "... ... SSL passphrase via file enabled."

    else
        echo "... SSL passphrase mode is deactivated."
    fi

# delete old configuration files
    echo "... ... Delete old web server configuration file..."
    for i in misp.conf misp.ssl.conf server-status.conf
    do
        [ -f /etc/apache2/sites-enabled/$i ] && rm -v /etc/apache2/sites-enabled/$i
    done

# Write HTTPS File
echo "... ... Write web server https configuration..."
cat << EOF > $HTTPS_FILE

ServerTokens Prod
${USE_SSL_PASSPHRASE_FILE}

<VirtualHost *:443>
    ${CONFIG_PART_FOR_HTTP_HTTPS}

    SSLEngine               On
    
    # for Modern: SSLProtocol             all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLProtocol             all -SSLv2 -SSLv3
    
    # Old
    # SSLCipherSuite          ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
    # Modern from 2019-06
    #SSLCipherSuite          ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
    # Intermediate from 2019-06
    SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
    
    SSLHonorCipherOrder     on
    SSLCompression          off
    SSLSessionTickets       off
    SSLOpenSSLConfCmd       DHParameters "${SSL_DH_FILE}"

    # OCSP Stapling, only in httpd 2.3.3 and later
    # SSLUseStapling          off
    # SSLStaplingResponderTimeout 5
    # SSLStaplingReturnResponderErrors off
    # SSLStaplingCache        shmcb:/var/run/ocsp(128000)

    SSLCertificateFile ${SSL_CERT}
    SSLCertificateKeyFile ${SSL_KEY}
    ${USE_SSL_CA}
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noe

EOF

else

echo "... ... Write web server http configuration..."
# Write HTTP File
cat << EOF > $HTTP_FILE

ServerTokens Prod

<VirtualHost *:80>
    ${CONFIG_PART_FOR_HTTP_HTTPS}
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noe

EOF

fi

#
#
# Add Ports file
echo "... ... Write web server ports file..."
cat <<EOF > $PORTS_FILE

# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 80
Listen 8080

<IfModule ssl_module>
    Listen 443
</IfModule>

<IfModule mod_gnutls.c>
    Listen 443
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

EOF

#
#
# Add Server_Status
a2enmod status
ALLOWED_IP_RANGE=""
for i in $(grep -Po  '[0-9.].*/[0-9][0-9]' /proc/net/fib_trie|sort|uniq)
do
    [ "127.0.0.1" = "$i" ] && continue
    ALLOWED_IP_RANGE="${ALLOWED_IP_RANGE}${i} "
done
cat <<EOF > $SERVER_STATUS_FILE

<VirtualHost *:8080>
            <Location /server-status>
                SetHandler server-status
                #Require local
                Require ip $ALLOWED_IP_RANGE
            </Location>
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noe

EOF

# Check Permissions
echo "... ... Check webserver file permissions..."
chmod 640 /etc/apache2/ports.conf /etc/apache2/sites-available/*
chown root.root /etc/apache2/ports.conf /etc/apache2/sites-available/*

echo "... Webserver configuration generation...finished"
