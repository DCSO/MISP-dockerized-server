#!/bin/bash

# bash is required for mysql init "${@:2}" only available in bash

set -e

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[ENTRYPOINT_MARIADB]${NC}"
DATADIR="/var/lib/mysql"
FOLDER_with_VERSIONS="/var/lib/mysql"


if [[ "$MYSQL_HOST" != "localhost" ]] && [[ "$MYSQL_HOST" != "misp-server" ]]; then
    echo "$STARTMSG Deactivate MariaDB Entrypoint because MYSQL_HOST='$MYSQL_HOST'."
    exit 0
fi

MYSQL_DATABASE=${MYSQL_DATABASE:-"misp"}
MYSQL_HOST=${MYSQL_HOST:-"localhost"}
[ -z "$MYSQL_ROOT_PASSWORD" ] && echo "$STARTMSG No MYSQL_ROOT_PASSWORD is set. Exit now." && exit 1
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-"misp"}
MYSQL_INIT_CMD=${MYSQL_INIT_CMD:-"mysql -u root -P $MYSQL_PORT -h $MYSQL_HOST -r -N"}



echo (){
    command echo -e "$@"
}

check_mysql(){
    # wait for Database come ready
    isDBup () {
        command echo "SHOW STATUS" | $MYSQL_INIT_CMD 1>/dev/null
        command echo $?
    }

    RETRY=10
    # shellcheck disable=SC2046
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "Waiting for database to come up"
        sleep 5
        RETRY=$(( RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    fi

}

start_mysql(){
    if [ $# -eq 0 ]; then
        gosu mysql mysqld 
    else
        gosu mysql "$@"
    fi
}

init_mysql(){

    echo "$STARTMSG Check if database is allready initialized"
    if [[ ! -e /var/lib/mysql/misp/users.ibd ]]; then
        echo "$STARTMSG MISP Database not found - Initializing database..."
    
        # Set root password
        if sudo mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE User='root';"; then
            echo "$STARTMSG root password changed"
        else 
            echo "$STARTMSG error initializing database"
        fi
        # Remove remote root
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"; then
            echo "$STARTMSG root remote access removed"
        else 
            echo "$STARTMSG error initializing database"
        fi
        # Remove anomynous user 
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "DELETE FROM mysql.user WHERE User='';"; then
            echo "$STARTMSG anomynous user removed"
        else 
            echo "$STARTMSG error initializing database"
        fi
        # Dropp test db
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "DROP DATABASE IF EXISTS test;"; then
            echo "$STARTMSG test database dropped"
        else 
            echo "$STARTMSG error initializing database"
        fi
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"; then
            echo "$STARTMSG privileges on test database removed"
        else 
            echo "$STARTMSG error initializing database"
        fi
        # Reload privileges
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"; then
            echo "$STARTMSG priviliges flushed"
        else 
            echo "$STARTMSG error initializing database"
        fi

        # Intilize misp db
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE ${MYSQL_DATABASE};"; then
            echo "$STARTMSG misp database created"
        else 
            echo "$STARTMSG error initializing database"
        fi
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"; then
            echo "$STARTMSG misp database user created"
        else 
            echo "$STARTMSG error initializing database"
        fi
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT USAGE ON *.* to ${MYSQL_USER}@localhost;"; then
            echo "$STARTMSG misp user access granted"
        else 
            echo "$STARTMSG error initializing database"
        fi
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES on ${MYSQL_DATABASE}.* to '${MYSQL_USER}'@'localhost';"; then
            echo "$STARTMSG misp user privileges granted"
        else 
            echo "$STARTMSG error initializing database"
        fi
        if sudo mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"; then 
            echo "$STARTMSG priviliges flushed"
        else 
            echo "$STARTMSG error initializing database"
        fi
        
        # Import the empty MISP database from MYSQL.sql
        if sudo cat /var/www/MISP/INSTALL/MYSQL.sql | mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}; then
            echo "$STARTMSG misp database setup script successfully imported"
        else 
            echo "$STARTMSG error initializing database"
        fi
    fi
}

########################################################
# START MAIN
########################################################

# Start mysql deamon
echo "$STARTMSG starting mysql..." && service mysql start
check_mysql
# Initialize MISP Database if not allready done
init_mysql
echo "$STARTMSG stopping mysql..." && service mysql stop
echo "$STARTMSG start longtime mysql..." && start_mysql "$@"
