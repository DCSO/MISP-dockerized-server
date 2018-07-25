#!/bin/bash


function check_apache(){
    curl -f http://localhost/ || exit 1
}

function check_mysql(){
    # exit with error if no databases are exists
    [ ! "$(mysql -u $MYSQL_USER -p$MYSQL_PASSWORD --execute 'show databases;'|grep $MYSQL_DATABASE)" == $MYSQL_DATABASE ] && exit 1
}

function check_redis(){
    [ "$(redis-cli -h localhost ping)" == "PONG" ] || exit 1
    #[ "$(redis-cli -h misp-redis ping)" == "PONG" ] || exit 1
}

# execute Funtions
check_apache
check_mysql
check_redis
exit 0