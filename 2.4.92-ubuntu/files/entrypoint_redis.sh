#!/bin/bash
set -e


function init_redis() {
# allow the container to be started with `--user`
[ -d "/redis_data_dir" ] || mkdir -p /redis_data_dir
pushd /redis_data_dir
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	chown -R redis .
	exec gosu redis "$0" "$@"
fi

exec "$@"
}

init_redis $CMD_REDIS