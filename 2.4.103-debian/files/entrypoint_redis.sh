#!/bin/sh
set -e

STARTMSG="[ENTRYPOINT_REDIS]"
REDIS_DATA="/redis_data_dir"

if [ "$REDIS_FQDN" = "localhost" ] || [ -z "$REDIS_FQDN" ] || [ "$REDIS_FQDN" = "misp-server" ]; then
	# allow the container to be started with `--user`
	[ -d "$REDIS_DATA" ] || mkdir -p "$REDIS_DATA"
	# change directory
	cd "$REDIS_DATA"
	# check if script is started as user redis if not do it!
	if [ "$(id -u)" = '0' ]; then
		chown -R redis "$REDIS_DATA"
		exec gosu redis "$0" "$CMD_REDIS"
	fi

	echo "$STARTMSG ###############	started REDIS with cmd: '$CMD_REDIS'	#############"

	redis-server "$CMD_REDIS"

else
	echo "$STARTMSG Deactivate local Redis server."
fi
