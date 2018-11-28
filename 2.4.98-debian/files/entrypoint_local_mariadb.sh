#!/bin/bash
set -e

DATADIR="/var/lib/mysql"
FOLDER_with_VERSIONS="/var/lib/mysql"

[ -z $MYSQL_DATABASE ] && export MYSQL_DATABASE=misp
[ -z $MYSQL_HOST ] && export MYSQL_HOST=localhost
[ -z "$MYSQL_ROOT_PASSWORD" ] && export MYSQL_ROOT_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" 


function upgrade(){
    for i in $FOLDER_with_VERSIONS
    do
        if [ ! -f $i/${NAME} ] 
        then
            # File not exist and now it will be created
            echo ${VERSION} > $i/${NAME}
        elif [ ! -f $i/${NAME} -a -z "$(cat $i/${NAME})" ]
        then
            # File exists, but is empty
            echo ${VERSION} > $i/${NAME}
        elif [ "$VERSION" == "$(cat $i/${NAME})" ]
        then
            # File exists and the volume is the current version
            echo "Folder $i is on the newest version."
        else
            # upgrade
            echo "Folder $i should be updated."

            ############ DO ANY!!!
        fi
    done
}

function start_mysql(){
    if [ -z "$@" ]; then
        gosu mysql mysqld 
    else
        gosu mysql $@
    fi
}

function init_mysql(){


echo "########################"
echo "mkdir -p $DATADIR/mysql" && mkdir -p $DATADIR/mysql
echo "chown -R mysql.mysql $DATADIR/*" && chown -R mysql.mysql $DATADIR/*
echo "########################"
echo 'Initializing database'
# "Other options are passed to mysqld." (so we pass all "mysqld" arguments directly here)
gosu mysql mysql_install_db --datadir="$DATADIR" --rpm "${@:2}"
echo 'Database initialized'

echo "########################"
echo "Start mysqld to setup"
#"$@" --skip-networking --socket="${SOCKET}" &
start_mysql &
pid="$!"
sleep 2
# test if mysqld is ready
i=0
while(true)
do
    [ -z "$(mysql -uroot -h $MYSQL_HOST -e 'select 1;'|tail -1|grep ERROR)" ] && break;
    echo "not ready..."
    sleep 3
    i+=1
    [ "$i" >= 10 ] && echo "can't start DB" && exit 1
done
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
# import MISP DB Scheme
echo "########################"
echo "Import MySQL scheme"
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < /var/www/MISP/INSTALL/MYSQL.sql

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

# Echo default Passwort
echo "########################"
echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
echo "########################"

}


########################################################
########################################################
########################################################
# START MAIN
########################################################
########################################################
########################################################


# create socket folder if not exists
[ ! -d "/var/run/mysqld" ] && echo "mkdir -p /var/run/mysqld" && mkdir -p /var/run/mysqld
echo "########################"
########################################################
# change ownership to mysql user and group
echo "chown -R mysql.mysql /var/run/mysqld" && chown -R mysql.mysql /var/run/mysqld
echo "########################"
########################################################
# Initialize mysql daemon
[ ! -d "$DATADIR/mysql" ] && echo "init mysql..." && init_mysql
echo "########################"
########################################################
# check volumes and upgrade if it is required
echo "upgrade if it is required..." && upgrade
########################################################
# Stop existing mysql deamon
echo "stopping mysql..." && service mysql stop
echo "########################"
########################################################
# Own the directory
echo "chown -R mysql.mysql $DATADIR/*" && chown -R mysql.mysql $DATADIR/*
echo "########################"
########################################################
# CHMOD the configuration files
echo "chmod -R 644 /etc/mysql/*" && chmod -R 644 /etc/mysql/*
echo "########################"
########################################################
# start mysql deamon
echo "start longtime mysql..." && start_mysql
echo "########################"
