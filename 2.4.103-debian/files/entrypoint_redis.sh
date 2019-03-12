#!/bin/bash
set -e

STARTMSG="[ENTRYPOINT_REDIS]"

function init_redis() {
	# allow the container to be started with `--user`
	[ -d "/redis_data_dir" ] || mkdir -p /redis_data_dir
	# change directory
	pushd /redis_data_dir
	# check if script is started as user redis if not do it!
	if [ "$1" = 'redis-server' ] && [ "$(id -u)" = '0' ]; then
		chown -R redis .
		exec gosu redis "$0" "$@"
	fi

	echo -e "$STARTMSG ###############	started REDIS with cmd: '$CMD_REDIS'	#############"
	exec "$@"
}

init_redis "$CMD_REDIS"