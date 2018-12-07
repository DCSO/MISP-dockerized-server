#!/bin/bash

function check_apache(){
    curl -f https://localhost/ || exit 1
}

function check_mysql(){
    # if no host is give default localhost
    [ -z $MYSQL_HOST ] && MYSQL_HOST=localhost
    # exit with error if no databases are exists
    [ ! "$(mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD --execute 'show databases;'|grep $MYSQL_DATABASE)" == $MYSQL_DATABASE ] && exit 1
}

function check_redis(){
    # if no host is give default localhost
    [ -z $REDIS_HOST ] && REDIS_HOST=localhost
    [ "$(redis-cli -h $REDIS_HOST ping)" == "PONG" ] || exit 1
}

function check_worker(){
    # Check worker intances process. This is no check if the worker are working!
    for i in default cache prio email
    do
        [ -z "$(ps ax|grep QUEUE=\'$i\')" ] && exit 1
    done
}

# execute Funtions
check_apache
check_mysql
check_redis
check_worker
exit 0