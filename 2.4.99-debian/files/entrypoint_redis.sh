#!/bin/bash
set -e

STARTMSG="[ENTRYPOINT_REDIS]"

CMD_REDIS=${CMD_REDIS:-redis-server --appendonly yes}


init_redis() {
	# allow the container to be started with `--user`
	[ -d "/redis_data_dir" ] || mkdir -p /redis_data_dir
	# change directory
	pushd /redis_data_dir

	# check if script is started as user redis if not do it!
	if [ "$1" = 'redis-server' ] && [ "$(id -u)" = '0' ]; then
		chown -R redis .
		gosu redis "$0" "$* --daemonize no --bind 0.0.0.0 --protected-mode no --logfile /dev/stdout"
	else
		echo -e "$STARTMSG ###############	started REDIS with cmd: '$CMD_REDIS'	#############"
		"$@"
	fi

	
}

# shellcheck disable=SC2086
init_redis $CMD_REDIS