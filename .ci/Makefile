#
#	Makefile
#
.PHONY: help build tags push notify-hub-docker-com

help:
	@echo -e "Please use a command: \n \
		make build v=<2.3-debian> \n \
		make build v=<2.3-debian> prod=true | If you want to build directly production ready images\n \
		make tags REPOURL= \n \
		make tags REPOURL= prod=true | If you want to add production ready images \n \
		make push REPOURL= USER= PW= \n \
		make notify-hub.docker.com URL= \n \
	"

build:
	@bash 02_build.sh $(v) $(prod)

tags:
	@bash 03_tagging.sh $(REPOURL) $(prod)

push:
	@bash 04_push.sh $(REPOURL) $(USER) $(PW)

notify-hub-docker-com:
	@bash 05_notify_hub.docker.com.sh $(URL)
