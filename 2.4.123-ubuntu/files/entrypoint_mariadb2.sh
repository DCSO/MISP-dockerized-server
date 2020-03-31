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

    echo "$STARTMSG Initializing database..."
    if [[ ! -e /var/lib/mysql/misp/users.ibd ]]; then
        debug "Setting up database"
    
        # Set root password
        sudo mysql -u ${DBUSER_ADMIN} -p -e "UPDATE mysql.user SET Password=PASSWORD('${DBPASSWORD_ADMIN}') WHERE User='root';"
        # Remove remote root
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
        # Remove anomynous user 
        "DELETE FROM mysql.user WHERE User='';"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "DELETE FROM mysql.user WHERE User='';"
        # Dropp test db
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "DROP DATABASE IF EXISTS test;"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
        # Reload privileges
        "FLUSH PRIVILEGES;"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "FLUSH PRIVILEGES;"

        # Intilize misp db
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "CREATE DATABASE ${DBNAME};"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "CREATE USER '${DBUSER_MISP}'@'localhost' IDENTIFIED BY '${DBPASSWORD_MISP}';"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "GRANT USAGE ON *.* to ${DBUSER_MISP}@localhost;"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "GRANT ALL PRIVILEGES on ${DBNAME}.* to '${DBUSER_MISP}'@'localhost';"
        sudo mysql -u ${DBUSER_ADMIN} -p${DBPASSWORD_ADMIN} -e "FLUSH PRIVILEGES;"
        
        # Import the empty MISP database from MYSQL.sql
        sudo cat /var/www/MISP/INSTALL/MYSQL.sql | mysql -u ${DBUSER_MISP} -p${DBPASSWORD_MISP} ${DBNAME}

        ########################################################
        # create debian.cnf
        debian_conf=/etc/mysql/debian.cnf
        echo "$STARTMSG Write $debian_conf"
        # add debian.cnf File
        cat << EOF > $debian_conf
        #	MYSQL Configuration from DCSO
        [client]
        host     = localhost
        user     = root
        password = $MYSQL_ROOT_PASSWORD
        socket   = /var/run/mysqld/mysqld.sock
        [mysql_upgrade]
        #host     = localhost
        user     = root
        password = $MYSQL_ROOT_PASSWORD
        socket   = /var/run/mysqld/mysqld.sock
        basedir  = /usr
EOF
        ########################################################
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
