#!/bin/bash
set -eu
export DEBIAN_FRONTEND=noninteractive

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  

STARTMSG="${Light_Green}[ENTRYPOINT_APACHE]${NC}"
ENTRYPOINT_PID_FILE="/entrypoint_apache.install"
[ ! -f $ENTRYPOINT_PID_FILE ] && touch $ENTRYPOINT_PID_FILE

#############   HELPER  #############
echo (){
    command echo -e "$STARTMSG $*"
}

missing_environment_var() {
    echo "Please set '$1' environment variable in docker-compose.override.yml file for misp-server!"
    exit
}
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
    MISP_BASE_PATH="/var/www/MISP"
    MISP_APP_PATH="/var/www/MISP/app"
    MISP_APP_CONFIG_PATH="$MISP_APP_PATH/Config"
    MISP_CONFIG="$MISP_APP_CONFIG_PATH/config.php"
    MISP_DATABASE_CONFIG="$MISP_APP_CONFIG_PATH/database.php"
    MISP_EMAIL_CONFIG="$MISP_APP_CONFIG_PATH/email.php"
    # CAKE
    CAKE_CONFIG="/var/www/MISP/app/Plugin/CakeResque/Config/config.php"
    # SSL
    SSL_CERT="/etc/apache2/ssl/cert.pem"
    SSL_KEY="/etc/apache2/ssl/key.pem"
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
    [ -z "${PGP_ENABLE+x}" ]     && PGP_ENABLE=0
    # SMIME
    [ -z "${SMIME_ENABLE+x}" ]   && SMIME_ENABLE=0
    # MISP
        # MISP_BASEURL="" && MISP_FQDN=""
    ( [ -z "${MISP_BASEURL+x}" ] && [ -z "$MISP_FQDN" ] ) && missing_environment_var MISP_FQDN
        # MISP_BASEURL="" && MISP_FQDN=<any>
    ( [ -z "${MISP_BASEURL+x}" ] && [ ! -z "$MISP_FQDN" ] ) && MISP_BASEURL="https://$(echo "$MISP_FQDN"|cut -d '/' -f 3)"
    [ -z "${MISP_SALT+x}" ]      && MISP_SALT="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 50)"
    [ -z "${MISP_ADD_ANALYZE_COLUMN+x}" ]      && MISP_ADD_ANALYZE_COLUMN="no"
    # MySQL
    [ -z "${MYSQL_HOST+x}" ]     && MYSQL_HOST=misp-db
    [ -z "${MYSQL_PORT+x}" ]     && MYSQL_PORT=3306
    [ -z "${MYSQL_USER+x}" ]     && MYSQL_USER=misp
    [ -z "${MYSQL_DATABASE+x}" ] && MYSQL_DATABASE=misp
    [ -z "${MYSQL_PASSWORD+x}" ] && missing_environment_var MYSQL_PASSWORD
    [ -z "${MYSQL_CMD+x}" ]      && MYSQL_CMD="mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -P $MYSQL_PORT -h $MYSQL_HOST -r -N  $MYSQL_DATABASE"
    # Mail
    [ -z "${MAIL_SENDER_ADDRESS+x}" ] && MAIL_SENDER_ADDRESS="no-reply@$MISP_FQDN"
    [ -z "${MAIL_ENABLE+x}" ] && MAIL_ENABLE="no"
    # Cake
    [ -z "${CAKE+x}" ]           && CAKE="$MISP_APP_PATH/Console/cake"
    # PHP
    [ -z "${PHP_MEMORY_LIMIT+x}" ]        && PHP_MEMORY_LIMIT="512M"
    [ -z "${PHP_MAX_EXECUTION_TIME+x}" ]  && PHP_MAX_EXECUTION_TIME="600"
    [ -z "${PHP_UPLOAD_MAX_FILESIZE+x}" ] && PHP_UPLOAD_MAX_FILESIZE="50M"
    [ -z "${PHP_POST_MAX_SIZE+x}" ]       && PHP_POST_MAX_SIZE="50M"
    # REDIS
    [ -z "${REDIS_FQDN+x}" ]     && REDIS_FQDN=misp-redis
    [ -z "${REDIS_PORT+x}" ]     && REDIS_PORT=6379
    [ -z "${REDIS_PW+x}" ]     && REDIS_PW=""
    # Apache 
    [ -z "${APACHE_CMD+x}" ]     && APACHE_CMD="none"


usage() {
    echo "Help!"
}

version() {
    echo "MISP version: ${VERSION-}"
    echo "Release date: ${RELEASE_DATE-}"
}


init_pgp(){
    local PGP_PUBLIC_KEY="$PGP_FOLDER/public.key"
    local MISP_PGP_PUBLIC_KEY="$MISP_APP_PATH/webroot/gpg.asc"
    
    if [  $PGP_ENABLE != 1 ]; then
        # if pgp should not be activated return
        echo "PGP should not be activated."
        return
    elif [ ! -f "$PGP_PUBLIC_KEY" ]; then
        # if secring.pgp do not exists return
        echo "No public PGP key found in $PGP_PUBLIC_KEY."
        return
    else
        echo "PGP key exists and copy it to MISP webroot."
        # Copy public key to the right place
        sh -c "cp $PGP_PUBLIC_KEY $MISP_PGP_PUBLIC_KEY"
        sh -c "chmod 440 $MISP_PGP_PUBLIC_KEY"
    fi

}

init_smime(){
    local SMIME_CERT="$SMIME_FOLDER/cert.pem"
    local MISP_SMIME_CERT="$MISP_APP_PATH/webroot/public_certificate.pem"
      
    if [ $SMIME_ENABLE != 1 ]; then 
        echo "S/MIME should not be activated."
        return
    elif [ -f "$SMIME_CERT" ]; then
        # If certificate do not exists exit
        echo "No Certificate found in $SMIME_CERT."
        return
    else
        echo "S/MIME Cert exists and copy it to MISP webroot." 
        ## Export the public certificate (for Encipherment) to the webroot
        sh -c "cp $SMIME_CERT $MISP_SMIME_CERT"
        sh -c "chmod 440 $MISP_SMIME_CERT"
    fi
    
}

start_apache() {
    # Apache gets grumpy about PID files pre-existing
    rm -f /run/apache2/apache2.pid
    # execute APACHE2
    /usr/sbin/apache2ctl -DFOREGROUND "${1-}"
}

add_analyze_column(){
    ORIG_FILE="/var/www/MISP/app/View/Elements/Events/eventIndexTable.ctp"
    PATCH_FILE="/eventIndexTable.patch"

    # Backup Orig File
    cp $ORIG_FILE ${ORIG_FILE}.bak
    # Patch file
    patch $ORIG_FILE < $PATCH_FILE
}

change_php_vars(){
    
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
}

init_misp_config(){
    echo "Configure MISP | Copy MISP default configuration files"
    
    [ -f $MISP_APP_CONFIG_PATH/bootstrap.php ] || cp $MISP_APP_CONFIG_PATH/bootstrap.default.php $MISP_APP_CONFIG_PATH/bootstrap.php
    [ -f $MISP_DATABASE_CONFIG ] || cp $MISP_APP_CONFIG_PATH/database.default.php $MISP_DATABASE_CONFIG
    [ -f $MISP_APP_CONFIG_PATH/core.php ] || cp $MISP_APP_CONFIG_PATH/core.default.php $MISP_APP_CONFIG_PATH/core.php
    [ -f $MISP_CONFIG ] || cp $MISP_APP_CONFIG_PATH/config.default.php $MISP_CONFIG

    echo "Configure MISP | Set DB User, Password and Host in database.php"
    sed -i "s/localhost/$MYSQL_HOST/" $MISP_DATABASE_CONFIG
    sed -i "s/db\s*login/$MYSQL_USER/" $MISP_DATABASE_CONFIG
    sed -i "s/8889/3306/" $MISP_DATABASE_CONFIG
    sed -i "s/db\s*password/$MYSQL_PASSWORD/" $MISP_DATABASE_CONFIG

    echo "Configure MISP | Set MISP-Url in config.php"
    sed -i "s_.*baseurl.*=>.*_    \'baseurl\' => \'$MISP_BASEURL\',_" $MISP_CONFIG
    #sudo $CAKE baseurl "$MISP_BASEURL"

    if [ "${MAIL_ENABLE}" = "yes" ]
    then
        echo "Configure MISP | Set Email in config.php"
        sed -i "s/email@address.com/$MAIL_SENDER_ADDRESS/" $MISP_CONFIG
        
        echo "Configure MISP | Set Admin Email in config.php"
        sed -i "s/admin@misp.example.com/$MAIL_SENDER_ADDRESS/" $MISP_CONFIG
    else
        sed -i "s/                        'disable_emailing'               => false,/                        'disable_emailing'               => true,/" $MISP_CONFIG
    fi
    # echo "Configure MISP | Set GNUPG Homedir in config.php"
    # sed -i "s,'homedir' => '/',homedir'                        => '/var/www/MISP/.gnupg'," $MISP_CONFIG

    echo "Configure MISP | Change Salt in config.php"
    sed -i "s,'salt'\\s*=>\\s*'','salt'                        => '$MISP_SALT'," $MISP_CONFIG

    echo "Configure MISP | Change Mail type from phpmailer to smtp"
    sed -i "s/'transport'\\s*=>\\s*''/'transport'                        => 'Smtp'/" $MISP_EMAIL_CONFIG
    
    #### CAKE ####
    echo "Configure Cake | Change Redis host to $REDIS_FQDN"
    sed -i "s/'host' => 'localhost'.*/'host' => '$REDIS_FQDN',          \/\/ Redis server hostname/" $CAKE_CONFIG

    ##############
    echo # add an echo command because if no command is done busybox (alpine sh) won't continue the script
}

setup_via_cake_cli(){
    [ -f "/var/www/MISP/app/Config/database.php"  ] || (echo "File /var/www/MISP/app/Config/database.php not found. Exit now." && exit 1)
    if [ -f "/var/www/MISP/app/Config/NOT_CONFIGURED" ]; then
        echo "Cake initializing started..."
        # Initialize user and fetch Auth Key
        sudo -E $CAKE userInit -q
        #AUTH_KEY=$(mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2| tail -1)
        # Setup some more MISP default via cake CLI
        sudo $CAKE baseurl "$MISP_BASEURL"
        # Tune global time outs
        sudo $CAKE Admin setSetting "Session.autoRegenerate" 1
        sudo $CAKE Admin setSetting "Session.timeout" 600
        sudo $CAKE Admin setSetting "Session.cookie_timeout" 3600
        # Enable GnuPG
        sudo $CAKE Admin setSetting "GnuPG.email" "$MAIL_SENDER_ADDRESS"
        sudo $CAKE Admin setSetting "GnuPG.homedir" "$MISP_BASE_PATH/.gnupg"
        #sudo $CAKE Admin setSetting "GnuPG.password" ""
        # Enable Enrichment set better timeouts
        sudo $CAKE Admin setSetting "Plugin.Enrichment_services_enable" true
        sudo $CAKE Admin setSetting "Plugin.Enrichment_hover_enable" true
        sudo $CAKE Admin setSetting "Plugin.Enrichment_timeout" 300
        sudo $CAKE Admin setSetting "Plugin.Enrichment_hover_timeout" 150
        sudo $CAKE Admin setSetting "Plugin.Enrichment_cve_enabled" true
        sudo $CAKE Admin setSetting "Plugin.Enrichment_dns_enabled" true
        sudo $CAKE Admin setSetting "Plugin.Enrichment_services_url" "http://misp-modules"
        sudo $CAKE Admin setSetting "Plugin.Enrichment_services_port" 6666
        # Enable Import modules set better timout
        # sudo $CAKE Admin setSetting "Plugin.Import_services_enable" true
        # sudo $CAKE Admin setSetting "Plugin.Import_services_url" "http://misp-modules"
        # sudo $CAKE Admin setSetting "Plugin.Import_services_port" 6666
        # sudo $CAKE Admin setSetting "Plugin.Import_timeout" 300
        # sudo $CAKE Admin setSetting "Plugin.Import_ocr_enabled" true
        # sudo $CAKE Admin setSetting "Plugin.Import_csvimport_enabled" true
        # # Enable Export modules set better timout
        # sudo $CAKE Admin setSetting "Plugin.Export_services_enable" true
        # sudo $CAKE Admin setSetting "Plugin.Export_services_url" "http://misp-modules"
        # sudo $CAKE Admin setSetting "Plugin.Export_services_port" 6666
        # sudo $CAKE Admin setSetting "Plugin.Export_timeout" 300
        # sudo $CAKE Admin setSetting "Plugin.Export_pdfexport_enabled" true
        # Enable installer org and tune some configurables
        sudo $CAKE Admin setSetting "MISP.host_org_id" 1

        [ -n "${MAIL_SENDER_ADDRESS+x}" ] && sudo $CAKE Admin setSetting "MISP.email" "$MAIL_SENDER_ADDRESS"
        [ "${MAIL_ENABLE-}" = "no" ] && sudo $CAKE Admin setSetting "MISP.disable_emailing" true
        
        sudo $CAKE Admin setSetting "MISP.contact" "$MAIL_SENDER_ADDRESS"
        # sudo $CAKE Admin setSetting "MISP.disablerestalert" true
        # sudo $CAKE Admin setSetting "MISP.showCorrelationsOnIndex" true
        # Provisional Cortex tunes
        sudo $CAKE Admin setSetting "Plugin.Cortex_services_enable" false
        # sudo $CAKE Admin setSetting "Plugin.Cortex_services_url" "http://127.0.0.1"
        # sudo $CAKE Admin setSetting "Plugin.Cortex_services_port" 9000
        # sudo $CAKE Admin setSetting "Plugin.Cortex_timeout" 120
        # sudo $CAKE Admin setSetting "Plugin.Cortex_services_url" "http://127.0.0.1"
        # sudo $CAKE Admin setSetting "Plugin.Cortex_services_port" 9000
        # sudo $CAKE Admin setSetting "Plugin.Cortex_services_timeout" 120
        # sudo $CAKE Admin setSetting "Plugin.Cortex_services_authkey" ""
        # sudo $CAKE Admin setSetting "Plugin.Cortex_ssl_verify_peer" false
        # sudo $CAKE Admin setSetting "Plugin.Cortex_ssl_verify_host" false
        # sudo $CAKE Admin setSetting "Plugin.Cortex_ssl_allow_self_signed" true
        # Various plugin sightings settings
        # sudo $CAKE Admin setSetting "Plugin.Sightings_policy" 0
        # sudo $CAKE Admin setSetting "Plugin.Sightings_anonymise" false
        # sudo $CAKE Admin setSetting "Plugin.Sightings_range" 365
        # Plugin CustomAuth tuneable
        # sudo $CAKE Admin setSetting "Plugin.CustomAuth_disable_logout" false
        # RPZ Plugin settings
        # sudo $CAKE Admin setSetting "Plugin.RPZ_policy" "DROP"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_walled_garden" "127.0.0.1"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_serial" "\$date00"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_refresh" "2h"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_retry" "30m"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_expiry" "30d"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_minimum_ttl" "1h"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_ttl" "1w"
        # sudo $CAKE Admin setSetting "Plugin.RPZ_ns" "localhost."
        # sudo $CAKE Admin setSetting "Plugin.RPZ_ns_alt" ""
        # sudo $CAKE Admin setSetting "Plugin.RPZ_email" "$MAIL_SENDER_ADDRESS"
        # Force defaults to make MISP Server Settings less RED
        sudo $CAKE Admin setSetting "MISP.language" "eng"
        #sudo $CAKE Admin setSetting "MISP.proposals_block_attributes" false
        # Redis block
        sudo $CAKE Admin setSetting "MISP.redis_host" "$REDIS_FQDN" 
        sudo $CAKE Admin setSetting "MISP.redis_port" "$REDIS_PORT"
        sudo $CAKE Admin setSetting "MISP.redis_database" 13
        sudo $CAKE Admin setSetting "MISP.redis_password" "$REDIS_PW"
        
        sudo $CAKE Admin setSetting "Plugin.ZeroMQ_redis_host" "$REDIS_FQDN"
        sudo $CAKE Admin setSetting "Plugin.ZeroMQ_redis_port" "$REDIS_PORT"
        sudo $CAKE Admin setSetting "Plugin.ZeroMQ_redis_password" "$REDIS_PW"

        # Force defaults to make MISP Server Settings less YELLOW
        # sudo $CAKE Admin setSetting "MISP.ssdeep_correlation_threshold" 40
        # sudo $CAKE Admin setSetting "MISP.extended_alert_subject" false
        # sudo $CAKE Admin setSetting "MISP.default_event_threat_level" 4
        # sudo $CAKE Admin setSetting "MISP.newUserText" "Dear new MISP user,\\n\\nWe would hereby like to welcome you to the \$org MISP community.\\n\\n Use the credentials below to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nPassword: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
        # sudo $CAKE Admin setSetting "MISP.passwordResetText" "Dear MISP user,\\n\\nA password reset has been triggered for your account. Use the below provided temporary password to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nYour temporary password: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
        # sudo $CAKE Admin setSetting "MISP.enableEventBlacklisting" true
        # sudo $CAKE Admin setSetting "MISP.enableOrgBlacklisting" true
        # sudo $CAKE Admin setSetting "MISP.log_client_ip" false
        # sudo $CAKE Admin setSetting "MISP.log_auth" false
        # sudo $CAKE Admin setSetting "MISP.disableUserSelfManagement" false
        # sudo $CAKE Admin setSetting "MISP.block_event_alert" false
        # sudo $CAKE Admin setSetting "MISP.block_event_alert_tag" "no-alerts=\"true\""
        # sudo $CAKE Admin setSetting "MISP.block_old_event_alert" false
        # sudo $CAKE Admin setSetting "MISP.block_old_event_alert_age" ""
        # sudo $CAKE Admin setSetting "MISP.incoming_tags_disabled_by_default" false
        # sudo $CAKE Admin setSetting "MISP.footermidleft" "This is an initial install"
        # sudo $CAKE Admin setSetting "MISP.footermidright" "Please configure and harden accordingly"
        # sudo $CAKE Admin setSetting "MISP.welcome_text_top" "Initial Install, please configure"
        # sudo $CAKE Admin setSetting "MISP.welcome_text_bottom" "Welcome to MISP, change this message in MISP Settings"
        
        # Force defaults to make MISP Server Settings less GREEN
        # sudo $CAKE Admin setSetting "Security.password_policy_length" 16
        # sudo $CAKE Admin setSetting "Security.password_policy_complexity" '/^((?=.*\d)|(?=.*\W+))(?![\n])(?=.*[A-Z])(?=.*[a-z]).*$|.{16,}/'

        # Set MISP Live
        # sudo $CAKE Live 1
        # Update the galaxies…
        #sudo $CAKE Admin updateGalaxies
        # Updating the taxonomies…
        #sudo $CAKE Admin updateTaxonomies
        # Updating the warning lists…
        #sudo $CAKE Admin updateWarningLists
        # Updating the notice lists…
        # sudo $CAKE Admin updateNoticeLists
        #curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST https://127.0.0.1/noticelists/update
        
        # Updating the object templates…
        # sudo $CAKE Admin updateObjectTemplates
        #curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST https://127.0.0.1/objectTemplates/update
    else
        echo "Cake setup: MISP is configured."
    fi
}

create_ssl_cert(){
    # If a valid SSL certificate is not already created for the server, create a self-signed certificate:
    while [ -f $SSL_PID_CERT_CREATER.proxy ]
    do
        echo "$(date +%T) -  misp-proxy container create currently the certificate. misp-server wait until misp-proxy is finished."
        sleep 2
    done
    ( [ ! -f $SSL_CERT ] && [ ! -f $SSL_KEY ] ) && touch ${SSL_PID_CERT_CREATER}.server && echo "Create SSL Certificate..." && openssl req -x509 -newkey rsa:4096 -keyout $SSL_KEY -out $SSL_CERT -days 365 -sha256 -subj "/CN=${HOSTNAME}" -nodes && rm ${SSL_PID_CERT_CREATER}.server
    echo # add an echo command because if no command is done busybox (alpine sh) won't continue the script
}

SSL_generate_DH(){
    while [ -f $SSL_PID_CERT_CREATER.proxy ]
    do
        echo "$(date +%T) -  misp-proxy container create currently the certificate. misp-server wait until misp-proxy is finish."
        sleep 5
    done
    [ ! -f $SSL_DH_FILE ] && touch ${SSL_PID_CERT_CREATER}.server  && echo "Create DH params - This can take a long time, so take a break and enjoy a cup of tea or coffee." && openssl dhparam -out $SSL_DH_FILE 2048 && rm ${SSL_PID_CERT_CREATER}.server
    echo # add an echo command because if no command is done busybox (alpine sh) won't continue the script
}

check_mysql(){
    # Test when MySQL is ready    

    # wait for Database come ready
    isDBup () {
        command echo "SHOW STATUS" | $MYSQL_CMD 1>/dev/null
        command echo $?
    }

    RETRY=100
    # shellcheck disable=SC2046
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "Waiting for database to come up"
        sleep 5
        # shellcheck disable=SC2004
        RETRY=$(( $RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    fi
}

init_mysql(){
    #####################################################################
    if [ -f "/var/www/MISP/app/Config/NOT_CONFIGURED" ]; then
        set -xv
        check_mysql
        # import MISP DB Scheme
        echo "... importing MySQL scheme..."
        $MYSQL_CMD -v < /var/www/MISP/INSTALL/MYSQL.sql
        echo "MySQL import...finished"
        set +xv
    fi
    echo
}

check_redis(){
    # Test when Redis is ready
    while (true)
    do
        [ "$(redis-cli -h "$REDIS_FQDN" -p "$REDIS_PORT" -a "$REDIS_PW" ping)" == "PONG" ] && break;
        echo "Wait for Redis..."
        sleep 2
    done
}

upgrade(){
    for i in $FOLDER_with_VERSIONS
    do
        if [ ! -f "$i"/"${NAME}" ] 
        then
            # File not exist and now it will be created
            echo "${VERSION}" > "$i"/"${NAME}"
        elif [ ! -f "$i"/"${NAME}" ] && [ -z "$(cat "$i"/"${NAME}")" ]
        then
            # File exists, but is empty
            echo "${VERSION}" > "$i"/"${NAME}"
        elif [ "$VERSION" == "$(cat "$i"/"${NAME}")" ]
        then
            # File exists and the volume is the current version
            echo "Folder $i is on the newest version."
        else
            # upgrade
            echo "Folder $i should be updated."
            case "$(cat "$i"/"$NAME")" in
            2.4.92)
                # Tasks todo in 2.4.92
                echo "#### Upgrade Volumes from 2.4.92 ####"
                ;;
            2.4.93)
                # Tasks todo in 2.4.92
                echo "#### Upgrade Volumes from 2.4.93 ####"
                ;;
            2.4.94)
                # Tasks todo in 2.4.92
                echo "#### Upgrade Volumes from 2.4.94 ####"
                ;;
            2.4.95)
                # Tasks todo in 2.4.92
                echo "#### Upgrade Volumes from 2.4.95 ####"
                ;;
            2.4.96)
                # Tasks todo in 2.4.92
                echo "#### Upgrade Volumes from 2.4.96 ####"
                ;;
            2.4.97)
                # Tasks todo in 2.4.92
                echo "#### Upgrade Volumes from 2.4.97 ####"
                ;;
            *)
                echo "Unknown Version, upgrade not possible."
                return
                ;;
            esac
            ############ DO ANY!!!
        fi
    done
}

##############   MAIN   #################

# If a customer needs a analze column in misp
echo "Check if analyze column should be added..." && [ "$MISP_ADD_ANALYZE_COLUMN" = "yes" ] && add_analyze_column

# Change PHP VARS
echo "Change PHP values ..." && change_php_vars

##### PGP configs #####
echo "Check if PGP should be enabled...." && init_pgp


echo "Check if SMIME should be enabled..." && init_smime

##### create a cert if it is required
echo "Check if a cert is required..." && create_ssl_cert

# check if DH file is required to generate
echo "Check if a dh file is required" && SSL_generate_DH

##### enable https config and disable http config ####
echo "Check if HTTPS MISP config should be enabled..."
    ( [ -f /etc/apache2/ssl/cert.pem ] && [ ! -f /etc/apache2/sites-enabled/misp.ssl.conf ] ) && mv /etc/apache2/sites-enabled/misp.ssl /etc/apache2/sites-enabled/misp.ssl.conf

echo "Check if HTTP MISP config should be disabled..."
    ( [ -f /etc/apache2/ssl/cert.pem ] && [ ! -f /etc/apache2/sites-enabled/misp.conf ] ) && mv /etc/apache2/sites-enabled/misp.conf /etc/apache2/sites-enabled/misp.http

##### check Redis
echo "Check if Redis is ready..." && check_redis

##### check MySQL
echo "Check if MySQL is ready..." && check_mysql

##### Import MySQL scheme
echo "Import MySQL scheme..." && init_mysql

##### initialize MISP-Server
echo "Initialize misp base config..." && init_misp_config

##### check if setup is new: - in the dockerfile i create on this path a empty file to decide is the configuration completely new or not
echo "Check if cake setup should be initialized..." && setup_via_cake_cli

##### Delete the initial decision file & reboot misp-server
echo "Check if misp-server is configured and file /var/www/MISP/app/Config/NOT_CONFIGURED exist"
    [ -f /var/www/MISP/app/Config/NOT_CONFIGURED ] && echo "delete init config file and reboot" && rm "/var/www/MISP/app/Config/NOT_CONFIGURED"

########################################################
# check volumes and upgrade if it is required
echo "Upgrade if it is required..." && upgrade

##### Check permissions #####
    echo "Configure MISP | Check permissions..."
    #echo "... chown -R www-data.www-data /var/www/MISP..." && chown -R www-data.www-data /var/www/MISP
    echo "... chown -R www-data.www-data /var/www/MISP..." && find /var/www/MISP -not -user www-data -exec chown www-data.www-data {} +
    echo "... chmod -R 0750 /var/www/MISP..." && find /var/www/MISP -perm 550 -type f -exec chmod 0550 {} + && find /var/www/MISP -perm 770 -type d -exec chmod 0770 {} +
    echo "... chmod -R g+ws /var/www/MISP/app/tmp..." && chmod -R g+ws /var/www/MISP/app/tmp
    echo "... chmod -R g+ws /var/www/MISP/app/files..." && chmod -R g+ws /var/www/MISP/app/files
    echo "... chmod -R g+ws /var/www/MISP/app/files/scripts/tmp" && chmod -R g+ws /var/www/MISP/app/files/scripts/tmp

# delete pid file
[ -f $ENTRYPOINT_PID_FILE ] && rm $ENTRYPOINT_PID_FILE


###### Unset Environment Variables
unset PHP_MAX_EXECUTION_TIME
unset PHP_MEMORY_LIMIT
unset PHP_POST_MAX_SIZE
unset PHP_UPLOAD_MAX_FILESIZE
unset REDIS_FQDN
unset REDIS_PORT
unset REDIS_PW


# START APACHE2
echo "####################################  started Apache2 with cmd: '$APACHE_CMD' ####################################"

##### Display tips
echo
echo
cat <<__WELCOME__
" ###########	MISP environment is ready	###########"
" Please go to: ${MISP_BASEURL}"
" Login credentials:"
"      Username: admin@admin.test"
"      Password: admin"
	
" Do not forget to change your SSL certificate with:    make change-ssl"
" ##########################################################"
Congratulations!
Your MISP-dockerized server has been successfully booted.
__WELCOME__


##### execute apache
[ "${APACHE_CMD-}" != "none" ] && start_apache "$APACHE_CMD"
[ "${APACHE_CMD-}" = "none" ] && start_apache
