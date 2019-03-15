#!/bin/sh

set -e

STARTMSG="[ENTRYPOINT_LOCAL_MARIADB]"
DATADIR="/var/lib/mysql"
FOLDER_with_VERSIONS="/var/lib/mysql"
    # create an pid file for the entrypoint script.
    # entrypoint_apache start only if file is not in place.
touch "$DATADIR/$0.pid"

[ -z "$MYSQL_DATABASE" ] && export MYSQL_DATABASE=misp
[ -z "$MYSQL_HOST" ] && export MYSQL_HOST=localhost
[ -z "$MYSQL_ROOT_PASSWORD" ] && echo "$STARTMSG No MYSQL_ROOT_PASSWORD is set. Exit now." && exit 1
[ -z "$MYSQL_PORT" ] && export MYSQL_PORT=3306
[ -z "$MYSQL_USER" ] && export MYSQL_USER=misp

[ -z "$MYSQLCMD" ] && export MYSQLCMD="mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -p $MYSQL_PORT -h $MYSQL_HOST -r -N"

check_mysql(){
    # Test when MySQL is ready    

    # wait for Database come ready
    isDBup () {
        echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
        echo $?
    }

    RETRY=10
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "Waiting for database to come up"
        sleep 5
        RETRY=$(( $RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    fi

}

upgrade(){
    for i in $FOLDER_with_VERSIONS
    do
        if [ ! -f "$i/${NAME}" ] 
        then
            # File not exist and now it will be created
            echo "$STARTMSG No version file exists. Will be created."
        elif [ ! -f "$i/${NAME}" -a -z "$(cat "$i/${NAME}")" ]
        then
            # File exists, but is empty
            echo "$STARTMSG Version file exists, but is empty."
        elif [ "$VERSION" = "$(cat "$i/${NAME}")" ]
        then
            # File exists and the volume is the current version
            echo "$STARTMSG Folder $i is on the newest version."
        else
            # upgrade
            echo "$STARTMSG Folder $i should be updated."

            ############ DO ANY!!!
        fi
    done
}

start_mysql(){
    if [ -z "$*" ]; then
        gosu mysql mysqld 
    else
        gosu mysql "$@"
    fi
}

init_mysql(){
echo "$STARTMSG Initializing database"
echo "$STARTMSG mkdir -p $DATADIR/mysql" && mkdir -p $DATADIR/mysql
echo "$STARTMSG chown -R mysql.mysql $DATADIR/*" && chown -R mysql.mysql $DATADIR/*
# "Other options are passed to mysqld." (so we pass all "mysqld" arguments directly here)
gosu mysql mysql_install_db --datadir="$DATADIR" --rpm ${@:2}
echo "$STARTMSG Database initialized"

echo "$STARTMSG Start mysqld to setup"
#"$@" --skip-networking --socket="${SOCKET}" &
start_mysql &
pid="$!"
sleep 2
# test if mysqld is ready
check_mysql
########################################################

mysql -uroot -h localhost << EOF
-- What's done in this file shouldn't be replicated
--  or products like mysql-fabric won't work
SET @@SESSION.SQL_LOG_BIN=0;

-- Delete all Users except root
DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost', '$HOSTNAME') ;
-- Set Password
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root' ;
--SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;

-- Create Root User with %
CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;

-- Grant Permissions
GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;

-- Create MISP DB
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;

-- Create MISP DB User    
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;
GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;

DROP DATABASE IF EXISTS test ;
FLUSH PRIVILEGES ;
EOF

########################################################
# create debian.cnf
debian_conf=/etc/mysql/debian.cnf

# add debian.cnf File
cat << EOF > $debian_conf
#	MYSQL Configuration from DCSO
[client]
host     = localhost
user     = root
password = $(echo $MYSQL_ROOT_PASSWORD)
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
#host     = localhost
user     = root
password = $(echo $MYSQL_ROOT_PASSWORD)
socket   = /var/run/mysqld/mysqld.sock
basedir  = /usr

EOF
    ########################################################

}




########################################################
# START MAIN
########################################################



# create socket folder if not exists
[ ! -d "/var/run/mysqld" ] && mkdir -p /var/run/mysqld && chown -R mysql.mysql /var/run/mysqld
########################################################
# Initialize mysql daemon
[ ! -d "$DATADIR/mysql" ] && init_mysql
########################################################
# check volumes and upgrade if it is required
#echo "$STARTMSG upgrade if it is required..." && upgrade
########################################################
# Stop existing mysql deamon
echo "$STARTMSG stopping mysql..." && service mysql stop
########################################################
# Own the directory
echo "$STARTMSG chown -R mysql.mysql $DATADIR/*" && chown -R mysql.mysql $DATADIR/*
########################################################
# CHMOD the configuration files
echo "$STARTMSG chmod -R 644 /etc/mysql/*" && chmod -R 644 /etc/mysql/*
########################################################
# start mysql deamon
    # delete PID file
rm "$DATADIR/$0.pid"
    # start daemon
echo "$STARTMSG start longtime mysql..." && start_mysql $@
