#!/bin/bash
set -eu
export DEBIAN_FRONTEND=noninteractive

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="[ENTRYPOINT_APACHE]"
# Syslog is used remove the color options!
[ "${LOG_SYSLOG_ENABLED-}" = "no" ] && STARTMSG="${Light_Green}$STARTMSG${NC}"

ENTRYPOINT_PID_FILE="/entrypoint_apache.install"
[ ! -f $ENTRYPOINT_PID_FILE ] && touch $ENTRYPOINT_PID_FILE

#############   HELPER  #############
echo (){
    command echo -e "$STARTMSG $*"
}

missing_environment_var() {
    echo "Please set '$*' environment variable in docker-compose.override.yml file for misp-server!"
    exit
}

# first_version=5.100.2
# second_version=5.1.2
# if version_gt $first_version $second_version; then
#      echo "$first_version is greater than $second_version !"
# fi'
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

#####################################

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
else
    # --help
    [ "$1" = "--help" ] && usage 
    # --version
    [ "$1" = "--version" ] && version
    # treat everything except -- as exec cmd
    [ "${1:0:2}" != "--" ] && exec "$@"

fi

###################################
#   Variables
###################################
    # MISP
    PATH_TO_MISP=${PATH_TO_MISP:-/var/www/MISP}
    MISP_APP_PATH="$PATH_TO_MISP/app"
    MISP_APP_CONFIG_PATH="$MISP_APP_PATH/Config"
    MISP_CONFIG="$MISP_APP_CONFIG_PATH/config.php"
    MISP_DATABASE_CONFIG="$MISP_APP_CONFIG_PATH/database.php"
    # CAKE
    CAKE=${CAKE:-"$MISP_APP_PATH/Console/cake"}
    CAKE_CONFIG="$MISP_APP_PATH/Plugin/CakeResque/Config/config.php"
    # SSL
    SSL_DH_FILE="/etc/apache2/ssl/dhparams.pem"
    SSL_PID_CERT_CREATER="/etc/apache2/ssl/SSL_create.pid"
    # PGP
    PGP_FOLDER="/var/www/MISP/.gnupgp"
    # SMIME
    SMIME_FOLDER="/var/www/MISP/.smime"
    # MISC
    FOLDER_with_VERSIONS="/var/www/MISP/app/tmp /var/www/MISP/app/files \
                        /var/www/MISP/app/Plugin/CakeResque/Config \
                        /var/www/MISP/app/Config \
                        /var/www/MISP/.gnupg \
                        /var/www/MISP/.smime \
                        /etc/apache2/ssl"
    UPGRADE_MISP=0
    OLD_MISP_VERSION=""

###################################
#   Parameter via environment
###################################

# Legacy:
[ -n "${MYSQLCMD-}" ] && MYSQL_CMD=$MYSQLCMD
[ -n "${SENDER_ADDRESS-}" ] && MAIL_SENDER_ADDRESS=$SENDER_ADDRESS
[ -n "${MISP_URL-}" ] && MISP_BASEURL=$MISP_URL
[ -n "${ADD_ANALYZE_COLUMN-}" ] && MISP_ADD_ANALYZE_COLUMN=$ADD_ANALYZE_COLUMN


# Defaults
    # PGP
    PGP_ENABLE=${PGP_ENABLE:-"0"}
    # SMIME
    SMIME_ENABLE=${SMIME_ENABLE:-"0"}
    # MISP
    MISP_FQDN=${MISP_FQDN:-"$(hostname)"}
    if [ -n "$MISP_FQDN" ]; then
        MISP_BASEURL=${MISP_BASEURL:-"https://$MISP_FQDN"}
    else
        MISP_BASEURL=${MISP_BASEURL:-"https://$MISP_FQDN"}
    fi
    MISP_SALT=${MISP_SALT:-"$(</dev/urandom tr -dc A-Za-z0-9 | head -c 50)"}
    MISP_ADD_ANALYZE_COLUMN=${MISP_ADD_ANALYZE_COLUMN:-"no"}
    MISP_EXTERNAL_URL=${MISP_EXTERNAL_URL:-""}
    MISP_RELATIVE_URL=${MISP_RELATIVE_URL:-"yes"}
    # MySQL
    MYSQL_HOST=${MYSQL_HOST:-"misp-db"}
    MYSQL_PORT=${MYSQL_PORT:-"3306"}
    MYSQL_USER=${MYSQL_USER:-"misp"}
    MYSQL_DATABASE=${MYSQL_DATABASE:-"misp"}
    [ -z "${MYSQL_PASSWORD+x}" ] && missing_environment_var MYSQL_PASSWORD
    MYSQL_CMD=${MYSQL_CMD:-""mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -P $MYSQL_PORT -h $MYSQL_HOST -r -N  $MYSQL_DATABASE""}
    # Mail
    MAIL_SENDER_ADDRESS=${MAIL_SENDER_ADDRESS:-"no-reply@$MISP_FQDN"}
    MAIL_CONTACT_ADDRESS=${MAIL_CONTACT_ADDRESS:-"$MAIL_SENDER_ADDRESS"}
    MAIL_ENABLE=${MAIL_ENABLE:-"no"}
    # PHP
    PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-"512M"}
    PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-"600"}
    PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-"50M"}
    PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-"50M"}
    # REDIS
    REDIS_FQDN=${REDIS_FQDN:-"misp-redis"}
    REDIS_PORT=${MYREDIS_PORTSQL_HOST:-"6379"}
    REDIS_PW=${REDIS_PW:-""}
    # Apache
    APACHE_CMD=${APACHE_CMD:-"none"}
    
# Functions
usage() {
    echo "Help!"
}

init_pgp(){
    echo "... init_pgp | Initialize PGP..."
    local PGP_PUBLIC_KEY="$PGP_FOLDER/public.key"
    local MISP_PGP_PUBLIC_KEY="$MISP_APP_PATH/webroot/gpg.asc"
    
    if [  "$PGP_ENABLE" != 1 ]; then
        # if pgp should not be activated return
        echo "... init_pgp | Initialize PGP is not required."
        return
    elif [ ! -f "$PGP_PUBLIC_KEY" ]; then
        # if secring.pgp do not exists return
        echo "... ... [ERROR] No public PGP key found in $PGP_PUBLIC_KEY."
        return
    else
        echo "... ... PGP key exists and copy it to MISP webroot."
        # Copy public key to the right place
        sh -c "cp $PGP_PUBLIC_KEY $MISP_PGP_PUBLIC_KEY"
        sh -c "chmod 440 $MISP_PGP_PUBLIC_KEY"
        echo "... init_pgp | Initialize PGP...finished"
    fi
}

init_smime(){
    echo "... init_smime | Initialize S/MIME..."
    local SMIME_CERT="$SMIME_FOLDER/cert.pem"
    local MISP_SMIME_CERT="$MISP_APP_PATH/webroot/public_certificate.pem"
      
    if [ "$SMIME_ENABLE" != 1 ]; then 
        echo "... init_smime | Initialize S/MIME is not required."
        return
    elif [ -f "$SMIME_CERT" ]; then
        # If certificate do not exists exit
        echo "... ... [ERROR] No Certificate found in $SMIME_CERT."
        return
    else
        echo "... ... S/MIME Cert exists and copy it to MISP webroot." 
        ## Export the public certificate (for Encipherment) to the webroot
        sh -c "cp $SMIME_CERT $MISP_SMIME_CERT"
        sh -c "chmod 440 $MISP_SMIME_CERT"
        echo "... init_smime | Initialize S/MIME...finished"
    fi
}

start_apache() {
    # Apache gets grumpy about PID files pre-existing
    rm -f /run/apache2/apache2.pid
    echo "####################################  started Apache2 with cmd: '$*' ####################################"
    # execute APACHE2
    /usr/sbin/apache2ctl -DFOREGROUND "$*"
}

add_analyze_column(){
    echo "... add_analyze_column | Add Analyze Column to MISP view..."
    if [ "$MISP_ADD_ANALYZE_COLUMN" = "yes" ]
    then
        ORIG_FILE="/var/www/MISP/app/View/Elements/Events/eventIndexTable.ctp"
        PATCH_FILE="/eventIndexTable.patch"

        # Backup Orig File
        cp $ORIG_FILE ${ORIG_FILE}.bak
        # Patch file
        patch $ORIG_FILE < $PATCH_FILE
        echo "... add_analyze_column | Add Analyze Column to MISP view...finished"
    else
        echo "... add_analyze_column | Add Analyze Column to MISP view is not required."
    fi

}

change_php_vars(){
    echo "... change_php_vars | PHP variable modifying started..."
    if [ -n "${PHP_INI-}" ]
    then
        PHP_FILES="$PHP_INI"
    else
        PHP_FILES="$(ls /etc/php/*/apache2/php.ini)"
    fi
    
    for FILE in $PHP_FILES
    do
        sed -i "s/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/" "$FILE"
        sed -i "s/max_execution_time = .*/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/" "$FILE"
        sed -i "s/upload_max_filesize = .*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" "$FILE"
        sed -i "s/post_max_size = .*/post_max_size = ${PHP_POST_MAX_SIZE}/" "$FILE"
    done
    echo "... change_php_vars | PHP variable modifying started...finished"
}

init_misp_config(){
    echo "... init_misp_config | Start MISP configuration initialization..."

    #echo "... ... Copy MISP default configuration files"
    [ -f "$MISP_APP_CONFIG_PATH/bootstrap.php" ] || cp "$MISP_APP_CONFIG_PATH/bootstrap.default.php" "$MISP_APP_CONFIG_PATH/bootstrap.php"
    [ -f "$MISP_DATABASE_CONFIG" ] || cp "$MISP_APP_CONFIG_PATH/database.default.php" "$MISP_DATABASE_CONFIG"
    [ -f "$MISP_APP_CONFIG_PATH/core.php" ] || cp "$MISP_APP_CONFIG_PATH/core.default.php" "$MISP_APP_CONFIG_PATH/core.php"
    [ -f "$MISP_CONFIG" ] || cp "$MISP_APP_CONFIG_PATH/config.default.php" "$MISP_CONFIG"

    #### DB ####
    #echo "... ... Set DB User, Password and Host in database.php"
    sed -i "s/localhost/$MYSQL_HOST/" "$MISP_DATABASE_CONFIG"
    sed -i "s/db\s*login/$MYSQL_USER/" "$MISP_DATABASE_CONFIG"
    sed -i "s/8889/3306/" "$MISP_DATABASE_CONFIG"
    sed -i "s/db\s*password/$MYSQL_PASSWORD/" "$MISP_DATABASE_CONFIG"

    #### BASE URL ####
    #echo "... ... Set MISP-Url in config.php"
    sed -i "s_.*baseurl.*=>.*_    \'baseurl\' => \'$MISP_BASEURL\',_" "$MISP_CONFIG"
    #sudo $CAKE baseurl "$MISP_BASEURL"

    #### SALT ####
    #echo "... ... Change Salt in config.php"
    sed -i "s,'salt'\\s*=>\\s*'','salt'                        => '$MISP_SALT'," "$MISP_CONFIG"
    
    #### Mail ####
    # echo "Configure MISP | Change Mail type from phpmailer to smtp"
    # sed -i "s/'transport'\\s*=>\\s*''/'transport'                        => 'Smtp'/" "$MISP_EMAIL_CONFIG"
    
    #### CAKE ####
    #echo "... ... Change Redis host to $REDIS_FQDN in $CAKE_CONFIG"
    sed -i "s/'host' => 'localhost'.*/'host' => '$REDIS_FQDN',          \/\/ Redis server hostname/" "$CAKE_CONFIG"
    
    #echo "... ... Change Redis port to $REDIS_PORT in $CAKE_CONFIG"
    sed -i "s/'port' => 6379.*/'port' => '$REDIS_PORT',          \/\/ Redis server port/" "$CAKE_CONFIG"

    ##############
    echo "... init_misp_config | Start MISP configuration initialization...finished"
}

upgrade_misp_config_via_cake_cli(){
    echo "... upgrade_misp_config_via_cake_cli | Check if MISP server should upgrade..."
    # Save old MISP Version
    [ -f "$MISP_APP_PATH/files/MISP-dockerized-server" ] && OLD_MISP_VERSION=$(cat "$MISP_APP_PATH/files/MISP-dockerized-server")

    # Check if it should upgrade
    [ ! "$(version_gt "$VERSION" "$OLD_MISP_VERSION")" ] && UPGRADE_MISP=1

    if [ "$UPGRADE_MISP" = 1 ];then
        echo "... ... Upgrade will be done ..."
        # Update Versionsfiles
        for i in $FOLDER_with_VERSIONS
        do
            command echo "$VERSION" > "$i/MISP-dockerized-server"
        done

        echo "... upgrade_misp_config_via_cake_cli | Check if MISP server should upgrade...not required"
        return
    else
        echo "... upgrade_misp_config_via_cake_cli | Check if MISP server should upgrade...finished"
    fi
    
}

init_via_cake_cli(){
    echo "... init_via_cake_cli | Cake initializing started..."
    local SUDO_WWW="gosu www-data"
    [ -f "/var/www/MISP/app/Config/database.php"  ] || (echo "File /var/www/MISP/app/Config/database.php not found. Exit now." && exit 1)
    
    if [ -f "$MISP_APP_CONFIG_PATH/NOT_CONFIGURED" ] || [ "$UPGRADE_MISP" = 1 ]; then
        # Initialize user and fetch Auth Key
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" userInit -q
        # Tune global time outs
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "Session.autoRegenerate" 0
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "Session.timeout" 600
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "Session.cookieTimeout" 3600
        # Change base url, either with this CLI command or in the UI
        [ "$UPGRADE_MISP" = 0 ] && [ "${MISP_RELATIVE_URL-}" != "yes" ] &&  $SUDO_WWW "$CAKE" Baseurl "$MISP_BASEURL"
        # example: 'baseurl' => 'https://<your.FQDN.here>',
        # alternatively, you can leave this field empty if you would like to use relative pathing in MISP
        # 'baseurl' => '',
        # The base url of the application (in the format https://www.mymispinstance.com) as visible externally/by other MISPs.
        # MISP will encode this URL in sharing groups when including itself. If this value is not set, the baseurl is used as a fallback.
        [ "$UPGRADE_MISP" = 0 ] && [ "${MISP_RELATIVE_URL-}" != "yes" ] &&  $SUDO_WWW "$CAKE" Admin setSetting "MISP.external_baseurl" "$MISP_EXTERNAL_URL"
        
        # Enable GnuPG
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "GnuPG.email" "$MAIL_SENDER_ADDRESS"
         $SUDO_WWW "$CAKE" Admin setSetting "GnuPG.homedir" "$PATH_TO_MISP/.gnupg"
        # FIXME: what if we have not gpg binary but a gpg2 one?
         $SUDO_WWW "$CAKE" Admin setSetting "GnuPG.binary" "$(command -v gpg)"
        # Enable installer org and tune some configurables
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.host_org_id" 1
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.email" "$MAIL_SENDER_ADDRESS"
        # Mail
        [ "${MAIL_ENABLE-}" = "no" ] &&  $SUDO_WWW "$CAKE" Admin setSetting "MISP.disable_emailing" true
        
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.contact" "$MAIL_CONTACT_ADDRESS"
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.disablerestalert" true
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.showCorrelationsOnIndex" true
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.default_event_tag_collection" 0
        # Force defaults to make MISP Server Settings less RED
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.language" "eng"
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.proposals_block_attributes" false
        # # Redis block
         $SUDO_WWW "$CAKE" Admin setSetting "MISP.redis_host" "$REDIS_FQDN"
         $SUDO_WWW "$CAKE" Admin setSetting "MISP.redis_port" "$REDIS_PORT"
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "MISP.redis_database" 13
         $SUDO_WWW "$CAKE" Admin setSetting "MISP.redis_password" "$REDIS_PW"
        
        ############################################################
        #
        #   DCSO Added
        #
        # Enable Enrichment
         $SUDO_WWW "$CAKE" Admin setSetting "Plugin.Enrichment_services_enable" true
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "Plugin.Enrichment_hover_enable" true
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "Plugin.Enrichment_timeout" 300
         [ "$UPGRADE_MISP" = 0 ] && $SUDO_WWW "$CAKE" Admin setSetting "Plugin.Enrichment_hover_timeout" 150
         $SUDO_WWW "$CAKE" Admin setSetting "Plugin.Enrichment_services_url" "http://misp-modules"
         $SUDO_WWW "$CAKE" Admin setSetting "Plugin.Enrichment_services_port" 6666
        # Redis for ZeroMQ
         $SUDO_WWW "$CAKE" Admin setSetting "Plugin.ZeroMQ_redis_host" "$REDIS_FQDN"
         $SUDO_WWW "$CAKE" Admin setSetting "Plugin.ZeroMQ_redis_port" "$REDIS_PORT"
         $SUDO_WWW "$CAKE" Admin setSetting "Plugin.ZeroMQ_redis_password" "$REDIS_PW"
        # Change Python bin directory
         $SUDO_WWW "$CAKE" Admin setSetting "MISP.python_bin" "/var/www/MISP/venv/bin/python3"

        echo "... init_via_cake_cli | Cake initializing started...finished"

    else
        echo "... init_via_cake_cli | Cake initializing not required."
    fi
}

create_ssl_cert(){
    /usr/local/bin/generate_self-signed-cert
}

create_ssl_dh(){
    echo "... create_ssl_dh | Create Diffie-Hellman key..."
    while [ -f "$SSL_PID_CERT_CREATER.proxy" ]
    do
        echo "... ... $(date +%T) -  misp-proxy container create currently the certificate. misp-server wait until misp-proxy is finish."
        sleep 5
    done
    
    if [ ! -f "$SSL_DH_FILE" ] 
    then
        touch ${SSL_PID_CERT_CREATER}.server
        echo "Create DH params - This can take a long time, so take a break and enjoy a cup of tea or coffee."
        openssl dhparam -out "$SSL_DH_FILE" 2048 
        rm "${SSL_PID_CERT_CREATER}.server"
        echo "... create_ssl_dh | Create Diffie-Hellman key...finished"
    else
        echo "... create_ssl_dh | Create Diffie-Hellman key is not required."
    fi

}

check_mysql(){
    echo "... check_mysql | Check if DB is available..."

    # wait for Database come ready
    isDBup () {
        command echo "SHOW STATUS" | $MYSQL_CMD 1>/dev/null
        command echo $?
    }

    RETRY=100
    # shellcheck disable=SC2046
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "... ... Waiting for database to come up"
        sleep 5
        # shellcheck disable=SC2004
        RETRY=$(( $RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "... ... Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    fi
    echo "... check_mysql | Check if DB is available...finished"
}

init_mysql(){
    echo "... init_mysql | Initialize DB..."
    if [ -f "/var/www/MISP/app/Config/NOT_CONFIGURED" ]; then
        check_mysql
        # import MISP DB Scheme
        echo "... ... importing MySQL scheme..."
        $MYSQL_CMD -v < /var/www/MISP/INSTALL/MYSQL.sql
        echo "... ... importing MySQL scheme...finished"
        echo "... init_mysql | Initialize DB...finished"
    else
        echo "... init_mysql | Initialize DB not required."
    fi
    
}

check_redis(){
    echo "... check_redis | Check if Redis is available..."
    # Test when Redis is ready
    while (true)
    do
        [ "$(redis-cli -h "$REDIS_FQDN" -p "$REDIS_PORT" -a "$REDIS_PW" ping)" == "PONG" ] && break;
        echo "... ... Wait for Redis..."
        sleep 2
    done
    echo "... check_redis | Check if Redis is available...finished"
}

remove_init_config_file() {
    echo "... remove_init_config_file | Remove init config file..."
    if [ -f /var/www/MISP/app/Config/NOT_CONFIGURED ] 
    then
        echo "... ... delete init config file"
        rm "/var/www/MISP/app/Config/NOT_CONFIGURED"
        # delete pid file
        [ -f $ENTRYPOINT_PID_FILE ] && rm $ENTRYPOINT_PID_FILE
        
        echo "... remove_init_config_file | Remove init config file...finished"
    else
        echo "... remove_init_config_file | Remove init config file is not required."
    fi
}

check_misp_permissions(){
    echo "... check_misp_permissions | Check MISP permissions..."
    echo "... ... chown -R www-data.www-data /var/www/MISP..." && find /var/www/MISP -not -user www-data -type f -type d -exec chown www-data.www-data {} +
    echo "... ... chmod -R 0750 /var/www/MISP..." && find /var/www/MISP -perm 550 -type f -exec chmod 0550 {} + && find /var/www/MISP -perm 770 -type d -exec chmod 0770 {} +
    echo "... ... chmod -R g+ws /var/www/MISP/app/tmp..." && chmod -R g+ws /var/www/MISP/app/tmp
    echo "... ... chmod -R g+ws /var/www/MISP/app/files..." && chmod -R g+ws /var/www/MISP/app/files
    echo "... ... chmod -R g+ws /var/www/MISP/app/files/scripts/tmp" && chmod -R g+ws /var/www/MISP/app/files/scripts/tmp
    echo "... check_misp_permissions | Check MISP permissions...finished"
}

add_webserver_configuration(){
    /usr/local/bin/generate_web_server_configuration
}

init_msmtp() {
    echo "... init_msmtp | Initialize MSMTP Mailing..."
    # Support for the script:
    # - https://github.com/philoles/docker-ssmtp/blob/master/0.1/ssmtp_custom.conf
    # - https://unix.stackexchange.com/questions/36982/can-i-set-up-system-mail-to-use-an-external-smtp-server
    # - https://stackoverflow.com/questions/6573511/how-do-i-specify-to-php-that-mail-should-be-sent-using-an-external-mail-server
    # - https://wiki.debian.org/sSMTP

    # Variables
    PATH_TO_MISP=${PATH_TO_MISP:-"/var/www/MISP"}
    CONFFILE="/var/www/.msmtprc"
    LOGFILE="/var/www/.msmtp.log"
    PHP_INI=${PHP_INI:-/etc/php/7.2/apache2/php.ini}
    UseAuthUser=""
    UseAuthPW=""
    UseAuth="off"

    # Check if Mail should be disabled.
    [ "$MAIL_ENABLE" = "no" ] && echo "Mail should be disabled." && sleep 3600

    # Environment Parameter
    MISP_FQDN=${MISP_FQDN:-'misp-dockerized-server'}
    MAIL_DOMAIN=${MAIL_DOMAIN:-'example.com'}
    MAIL_SENDER_ADDRESS=${MAIL_SENDER_ADDRESS:-'MISP-dockerized@example.com'}
    MAIL_RELAYHOST=${MAIL_RELAYHOST:-'misp-postfix'}
    MAIL_RELAYHOST_PORT=${MAIL_RELAYHOST_PORT:-25}
    UseTLS=${MAIL_TLS:-'off'}
    UseSTARTTLS=${MAIL_TLS:-'off'}
    [ -n "$MAIL_RELAY_USER" ] && UseAuthUser="user $MAIL_RELAY_USER"
    [ -n "$MAIL_RELAY_PASSWORD" ] && UseAuthPW="password $MAIL_RELAY_PASSWORD"
    [ -n "$MAIL_RELAY_USER" ] && [ -n "$MAIL_RELAY_PASSWORD" ] && UseAuth="on"

    # Rewrite Configuration
    #echo "... ... Write configuration ..."
cat << EOF > "$CONFFILE"
# Set defaults.
defaults

# Enable or disable TLS/SSL encryption.
auth $UseAuth
tls $UseTLS
tls_starttls $UseSTARTTLS
tls_certcheck on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

# Set up a default account's settings.
account default
add_missing_from_header on
logfile ~/.msmtp.log
host "$MAIL_RELAYHOST"
port $MAIL_RELAYHOST_PORT
domain "$MISP_FQDN"
maildomain "$MAIL_DOMAIN"
$UseAuthUser
$UseAuthPW
from "$MAIL_SENDER_ADDRESS"

EOF

    # Post Tasks
    #echo "... ... Start post-tasks ..."
    # create Logfile
    [ ! -f "$LOGFILE" ] && touch "$LOGFILE"
    # Change Owner
    chown www-data:root "$CONFFILE" "$LOGFILE"
    # Change file permissions
    chmod 600 "$CONFFILE" "$LOGFILE"
    # Change PHP Sendmail Path
    sed -i 's,;sendmail_path =,sendmail_path = \"/usr/bin/msmtp -t\",' "$PHP_INI"

    echo "... init_msmtp | Initialize MSMTP Mailing...finished"
}

##############   MAIN   #################

# If a customer needs a analze column in misp
echo "Add Analyze Column..." && add_analyze_column

# Change PHP VARS
echo "Change PHP values ..." && change_php_vars

##### PGP configs #####
echo "Initialize PGP...." && init_pgp

##### S/MIME configs #####
echo "Initialize S/MIME..." && init_smime

##### check Redis
echo "Check Redis ready..." && check_redis

##### check MySQL
echo "Check MySQL ready..." && check_mysql

##### Import MySQL scheme
echo "Initialize MySQL Scheme..." && init_mysql

##### initialize MISP-Server
echo "Initialize MISP Base Configuration..." && init_misp_config

##### change MSMTP configuration
echo "Initialize Mail..." && init_msmtp

##### check if setup is new: - in the dockerfile i create on this path a empty file to decide is the configuration completely new or not
echo "Check upgrade tasks..." && upgrade_misp_config_via_cake_cli
echo "Initialize MISP via Cake..." && init_via_cake_cli

##### Check permissions #####
echo "MISP Permissions..." && check_misp_permissions

##### create a cert if it is required
echo "Create Certificate File..." && create_ssl_cert

# check if DH file is required to generate
echo "Create DH File..." && create_ssl_dh

##### enable https config and disable http config ####
echo "Add Webserver Configuration..." && add_webserver_configuration


########################################################


##### Delete the initial decision file & reboot misp-server
echo "Remove Init File..." && remove_init_config_file


########################################################

# START APACHE2
##### execute apache
[ "${APACHE_CMD-}" != "none" ] && start_apache "$APACHE_CMD"
[ "${APACHE_CMD-}" = "none" ] && start_apache
