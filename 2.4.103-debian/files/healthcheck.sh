#!/bin/sh
set -e 
STARTMSG="[HEALTHCHECK]"

check_apache(){
    curl -fk https://localhost/ || (echo "$STARTMSG Error at apache2." && exit 1)
}

check_mysql(){
    [ -z "$MYSQL_DATABASE" ] && export MYSQL_DATABASE=misp
    [ -z "$MYSQL_HOST" ] && export MYSQL_HOST=misp-db
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

    # exit with error if no databases are exists
    [ ! "$(MYSQLCMD -e 'show databases;'|grep $MYSQL_DATABASE)" = $MYSQL_DATABASE ] && echo "$STARTMSG No MySQL database found." && exit 1
}

check_redis(){
    # if no host is give default localhost
    [ -z "$REDIS_HOST" ] && REDIS_HOST=localhost
    [ "$(redis-cli -h $REDIS_HOST ping)" = "PONG" ] || (echo "$STARTMSG No active Redis found." && exit 1)
}

check_worker(){
    # Check worker intances process. This is no check if the worker are working!
    for i in default cache prio email
    do
        [ -z "$(pgrep -ax QUEUE=\'$i\')" ] && echo "$STARTMSG No active $i worker found."  && exit 1
    done
}

# execute Funtions
check_apache
check_mysql
check_redis
check_worker
exit 0