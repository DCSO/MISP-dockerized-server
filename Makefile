#
#	Makefile
#
.PHONY: help test test-travis build tags push 

help:
	echo "Please use a command"

test:
	true

test-travis:
	.travis/travis-cli.sh check

build:
	.travis/build.sh $(v) $(dev)

tags:
	.travis/tagging.sh

push:
	.travis/push.sh

install:
	.travis/main.sh

notify-hub-docker-com:
	.travis/notify_hub.docker.com.sh $(TOKEN)