#!/bin/bash

# check if backup folder allready exist
if [[ ! -e /srv/MISP-dockerized/backup ]]; then
    mkdir -p "/srv/MISP-dockerized/backup"
    chmod 755 "/srv/MISP-dockerized/backup"
fi