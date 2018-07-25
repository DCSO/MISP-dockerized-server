#!/bin/bash
set -e

DATADIR="/var/lib/mysql"

function check_and_link_error(){
    [ -e $1 ] && rm $1;
    ln -s /dev/stderr $1
}
function check_and_link_out(){
    [ -e $1 ] && rm $1;
    ln -s /dev/stdout $1
}

check_and_link_error "/var/log/mysql/error.log"

MYSQL_DATABASE=$MYSQL_DATABASE

start_mysql(){
    if [ -z "$@" ]; then
        gosu mysql mysqld 
    else
        gosu mysql $@
    fi
}

########################################################
# create socket folder
[ ! -d "/var/run/mysqld" ] && echo "mkdir -p /var/run/mysqld" && mkdir -p /var/run/mysqld
########################################################
# change ownership to mysql user and group
echo "chown -R mysql.mysql /var/run/mysqld" && chown -R mysql.mysql /var/run/mysqld
########################################################
# create Directory
echo "########################"
if [ ! -d "$DATADIR/mysql" ] 
    then
        echo "mkdir -p $DATADIR/mysql" && mkdir -p $DATADIR/mysql
        echo "chown -R mysql.mysql $DATADIR/mysql" && chown -R mysql.mysql $DATADIR/mysql
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
            [ -z "$(mysql -uroot -h localhost -e 'select 1;'|tail -1|grep ERROR)" ] && break;
            echo "not ready..."
            sleep 3
            i+=1
            [ "$i" >= 10 ] && echo "can't start DB" && exit 1
        done
        ########################################################
        echo "########################"
        # Create Root Password if none is given
        if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
            export MYSQL_ROOT_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
            echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
        fi


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

        # import MISP DB Scheme
        echo "########################"
        echo "Import MySQL scheme"
        mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < /var/www/MISP/INSTALL/MYSQL.sql
        #############################
fi

########################################################
# create debian.cnf
debian_conf=/etc/mysql/debian.cnf

# add debian.cnf File
cat << EOF > $debian_conf
#	MYSQL Configuration from DCSO
[client]
#host     = localhost
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



echo "########################"
echo "stopping mysql..."
service mysql stop
echo "start longtime mysql..."
start_mysql