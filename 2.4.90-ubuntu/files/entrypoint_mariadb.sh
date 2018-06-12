#!/bin/bash
set -e

###############################
echo "started mysql witch CMD: '$CMD_MYSQL'"
# create socket folder
mkdir -p /var/run/mysqld
# change ownership to mysql user and group
chown -R mysql.mysql /var/run/mysqld

# debian.cnf
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

#############################

# Start MySQL DB
/init_mariadb.sh $CMD_MYSQL