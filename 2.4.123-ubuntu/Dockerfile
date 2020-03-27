#FROM debian:stretch-slim
FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical

# DCSO Required Software
RUN apt-get update; apt-get install -y \ 
locales \
iputils-ping \
net-tools \
supervisor \
gosu \
wget \
rsyslog \
sudo \
&& apt-get autoremove -y && apt-get clean -y

# Set locals
ARG LANG=en_US.UTF-8
RUN locale-gen ${LANG}

#########################    START  MISP Guide

# 1/ Minimal Ubuntu install 
# based on: https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh
# -------------------------

#RUN wget -O /tmp/INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh; \
#    bash /tmp/INSTALL.sh
##### Avoid tzdata dialog during install
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

##### Install core dependencies
RUN sudo apt install -qy \
    curl gcc git gnupg-agent make openssl redis-server neovim unzip zip libyara-dev python3-yara python3-redis python3-zmq sqlite3 \
    mariadb-client \
    mariadb-server \
    apache2 apache2-doc apache2-utils \
    python3-dev python3-pip python3-venv libpq5 libjpeg-dev libfuzzy-dev ruby asciidoctor \
    libxml2-dev libxslt1-dev zlib1g-dev python3-setuptools expect;

##### Install PHP 7.2 dependencies
RUN sudo apt update; \
    sudo apt install -qy \
    libapache2-mod-php \
    php php-cli \
    php-dev \
    php-json php-xml php-mysql php7.2-opcache php-readline php-mbstring \
    php-redis php-gnupg \
    php-gd;

##### Install MISP Core
ARG MISP_TAG=${VERSION}
ENV MISP_TAG=${MISP_TAG}
ENV WWW_USER="www-data"
ENV PATH_TO_MISP="/var/www/MISP"
ENV SUDO_WWW="sudo -H -u ${WWW_USER}"

RUN git clone https://github.com/MISP/MISP.git ${PATH_TO_MISP}; \
    cd ${PATH_TO_MISP}; git checkout tags/v${MISP_TAG}; \
    chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}; \
    # Make git ignore filesystem permission differences
    cd ${PATH_TO_MISP}; git config core.filemode false; \
    # CakePHP and a lot of other things is included as a submodule of MISP, execute the following commands to let git fetch it:
    cd ${PATH_TO_MISP}; git submodule update --init --recursive; \
    # Make git ignore filesystem permission differences for submodules
    cd ${PATH_TO_MISP}; git submodule foreach --recursive git config core.filemode false

# Create a python3 virtualenv
RUN $SUDO_WWW python3 -m venv ${PATH_TO_MISP}/venv

# Make PIP happy
RUN sudo mkdir /var/www/.cache/; \
    sudo chown www-data:www-data /var/www/.cache;

RUN ${PATH_TO_MISP}/app/files/scripts; \
    $SUDO_WWW git clone https://github.com/CybOXProject/python-cybox.git; \
    $SUDO_WWW git clone https://github.com/STIXProject/python-stix.git; \
    $SUDO_WWW git clone https://github.com/MAECProject/python-maec.git; \
    $SUDO_WWW git clone https://github.com/CybOXProject/mixbox.git

# install mixbox to accommodate the new STIX dependencies:
RUN cd ${PATH_TO_MISP}/app/files/scripts/mixbox; \
    $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install .

RUN cd ${PATH_TO_MISP}/app/files/scripts/python-cybox; \
    $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install .

RUN cd ${PATH_TO_MISP}/app/files/scripts/python-stix; \
    $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install .

RUN cd $PATH_TO_MISP/app/files/scripts/python-maec; \
    $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install .

RUN $SUDO_WWW $PATH_TO_MISP/venv/bin/pip install -I antlr4-python3-runtime==4.7.2; \
    # install STIX2.0 library to support STIX 2.0 export:
    cd ${PATH_TO_MISP}/cti-python-stix2; \
    $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install .

# install PyMISP
RUN cd ${PATH_TO_MISP}/PyMISP; \
    $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install .

# install pydeep
RUN $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install git+https://github.com/kbandla/pydeep.git

# install lief
RUN $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install https://github.com/lief-project/packages/raw/lief-master-latest/pylief-0.9.0.dev.zip

# install zmq needed by mispzmq
RUN $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install zmq redis

# install python-magic
RUN $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install python-magic

# install plyara
RUN $SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip install plyara

##### Install CakePHP
# Once done, install CakeResque along with its dependencies 
# if you intend to use the built in background jobs:
RUN cd ${PATH_TO_MISP}/app; \
  sudo mkdir /var/www/.composer ; sudo chown $WWW_USER:$WWW_USER /var/www/.composer; \
  $SUDO_WWW php composer.phar install

# Enable CakeResque with php-redis
RUN sudo phpenmod redis; \
    sudo phpenmod gnupg

# To use the scheduler worker for scheduled tasks, do the following:
RUN $SUDO_WWW cp -fa ${PATH_TO_MISP}/INSTALL/setup/config.php ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php

##### Set permissions
RUN sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}; \
    sudo chmod -R 750 ${PATH_TO_MISP}; \
    sudo chmod -R g+ws ${PATH_TO_MISP}/app/tmp; \
    sudo chmod -R g+ws ${PATH_TO_MISP}/app/files; \
    sudo chmod -R g+ws $PATH_TO_MISP/app/files/scripts/tmp


##### Configure Apache
# add HTTP MISP Config
RUN rm /etc/apache2/sites-enabled/*;
COPY files/etc/apache2/sites-enabled/misp.ssl /etc/apache2/sites-enabled/
COPY files/etc/apache2/sites-enabled/misp.conf /etc/apache2/sites-enabled/
COPY files/etc/apache2/ports.conf /etc/apache2/ports.conf
RUN set -eu \
    chmod 640 /etc/apache2/ports.conf; \
    chown root.root /etc/apache2/ports.conf; \
    chmod 640 /etc/apache2/sites-available/*; \
    chown root.root /etc/apache2/sites-available/*; \
# Configure Apache
    sudo a2dismod status; \
    sudo a2enmod ssl; \
    sudo a2enmod rewrite; \
    sudo a2enmod headers

##### Enable Log rotation
# MISP saves the stdout and stderr of its workers in /var/www/MISP/app/tmp/logs
# To rotate these logs install the supplied logrotate script:
RUN sudo cp /var/www/MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp

##### Configure Database
# add own mysql config
COPY files/etc/mysql/mariadb.conf.d/DCSO.cnf /etc/mysql/mariadb.conf.d/

##### Prepare mail encryption
RUN set -eu; \
    # for S/MIME
    $SUDO_WWW mkdir /var/www/MISP/.smime; \
    $SUDO_WWW chmod 500 /var/www/MISP/.smime; \
    # for PGP
    $SUDO_WWW mkdir /var/www/MISP/.gnupg; \
    $SUDO_WWW chmod 700 /var/www/MISP/.gnupg; \
    # Create empty file for configurations checks in entrypoint_apache.sh
    touch "/var/www/MISP/app/Config/NOT_CONFIGURED";

##### Copy "Mode for Ralf" patch File for MISP Events Page with additional Analyse Column
COPY --chown=www-data:www-data files/var/www/MISP/app/View/Elements/Events/eventIndexTable.patch /

##### Setting up background workers
COPY files/etc/rc.local /etc/
COPY files/etc/systemd/system/misp-workers.service /etc/systemd/system/
RUN sudo chmod +x $PATH_TO_MISP/app/Console/worker/start.sh; \
    chmod 744 /etc/rc.local; \
    sudo systemctl daemon-reload; \
    sudo systemctl enable --now misp-workers

##### Install and configure postfix
# Copy files to postfix container
RUN apt install -qy postfix
COPY files/etc/postfix/* /etc/postfix/
RUN sudo postfix reload

##### Copy additional scripts
# MISP Update and MISP Cron
COPY --chown=www-data:www-data files/usr/local/bin/misp_update.sh /usr/local/bin/
COPY --chown=www-data:www-data files/usr/local/bin/misp_cron.sh /usr/local/bin/

##### Finish image
# Healthcheck
COPY files/healthcheck.sh /
HEALTHCHECK --interval=1m --timeout=45s --retries=3 CMD ["/healthcheck.sh"]

# Entrypoints
COPY files/entrypoint_apache.sh /
COPY files/entrypoint_cron.sh /
COPY files/entrypoint_mariadb.sh /
COPY files/entrypoint_postfix.sh /
COPY files/entrypoint_redis.sh /
COPY files/entrypoint_rsyslog.sh /
COPY files/entrypoint_workers.sh /
COPY files/entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]

# Change Workdirectory
WORKDIR /var/www/MISP

# Variables for labels:
ARG VENDOR="DCSO GmbH"
ARG COMPONENT="server"
ARG BUILD_DATE
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
ARG RELEASE_DATE
ARG NAME="MISP-dockerized-${COMPONENT}"
ARG DESCRIPTION="This docker container is part of the DCSO MISP dockerized environment."
ARG DOCUMENTATION="https://github.com/DCSO/MISP-dockerized"
ARG AUTHOR="DCSO MISP Docker Team <misp.docker@dcso.de>"
ARG LICENSE="BSD-3-Clause"

##### Set environment variables
ENV CMD_MYSQL=mysqld \
CMD_APACHE=none \
CMD_REDIS="--appendonly yes" \
NAME=${NAME} \
VERSION=${VERSION} \
RELEASE_DATE=${RELEASE_DATE} \
# Environment Variable for Proxy
http_proxy="" \ 
https_proxy="" \
no_proxy="0.0.0.0" \
# MYSQL Vars
MYSQL_HOST="localhost" \
MYSQL_DATABASE="misp" \
MYSQL_USER="misp" \
MYSQL_PASSWORD="ChangeMe123!" \
# POSTFIX
# Hostname for the Mailserver
HOSTNAME=misp \
# Domain for Outgoing Mail
DOMAIN=example.com \
# Sender for local postfix outgoing Mails
SENDER_ADDRESS=admin@example.com \
# Relahost to Send Mails
RELAYHOST=smtp.example.local:587 \
# RELAY User and Password
RELAY_USER=misp \
RELAY_PASSWORD=ChangeMe \
# Allow only MISP Docker Container Access
DOCKER_NETWORK=192.168.47.0/28 \
# You need to get more postfix output for a specified host normally the relayhost or misp-server
DEBUG_PEER=none \
# Set locals
# ENV LC_ALL ${LANG}
LANGUAGE=en_US:en


# Labels
LABEL org.label-schema.build-date="${BUILD_DATE}" \
        org.label-schema.name="${NAME}" \
        org.label-schema.description="${DESCRIPTION}" \
        org.label-schema.vcs-ref="${VCS_REF}" \
        org.label-schema.vcs-url="${GIT_REPO}" \
        org.label-schema.url="${GIT_REPO}" \
        org.label-schema.vendor="${VENDOR}" \
        org.label-schema.version="${VERSION}" \
        org.label-schema.usage="${DOCUMENTATION}" \
        org.label-schema.schema-version="1.0.0-rc1"

LABEL   org.opencontainers.image.created="${BUILD_DATE}" \
        org.opencontainers.image.url="${GIT_REPO}" \
        org.opencontainers.image.source="${GIT_REPO}" \
        org.opencontainers.image.version="${VERSION}" \
        org.opencontainers.image.revision="${VCS_REF}" \
        org.opencontainers.image.vendor="${VENDOR}" \
        org.opencontainers.image.title="${NAME}" \
        org.opencontainers.image.description="${DESCRIPTION}" \
        org.opencontainers.image.documentation="${DOCUMENTATION}" \
        org.opencontainers.image.authors="${AUTHOR}" \
        org.opencontainers.image.licenses="${LICENSE}"

#       End of DCSO MISP Config Part
#########################################
