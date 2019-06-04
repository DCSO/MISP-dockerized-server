FROM debian:stretch-slim
ENV DEBIAN_FRONTEND noninteractive

# DCSO Required Software
RUN apt-get update; apt-get install -y \ 
        locales \
        supervisor \
        gosu \
        wget \
        curl \
        rsyslog \
        bash \
        ssmtp \
    && apt-get autoremove -y \
    && apt-get clean -y

# Set locals
ARG LANG=en_US.UTF-8
RUN locale-gen ${LANG}

#########################    START  MISP Guide

# 1/ Minimal Ubuntu install
# -------------------------

    # Install Postfix dependency
    RUN apt-get update -y \
        && apt-get install postfix -y \
        && apt-get autoremove -y \
        && apt-get clean -y


    # 2/ Install LAMP & dependencies
    # ------------------------------
    # Install required software
    ## Installation of libfuzzy-dev is required for pydeep
    
RUN apt-get install -y \
        curl gcc git gpg-agent make python python3 openssl \
        redis-server sudo vim zip unzip virtualenv libfuzzy-dev sqlite3 \
        && apt-get autoremove -y && apt-get clean -y

RUN apt-get install -y \
        python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools \
        && apt-get autoremove -y && apt-get clean -y

#     RUN apt-get install -y \
#         gcc \
#         && apt-get autoremove -y && apt-get clean -y

#     RUN apt-get install -y \
#         curl git make sudo vim zip unzip \
#         openssl \
#         gpg-agent \
#         python3 \
#         #redis-server \
#         libyara-dev \
#         && apt-get autoremove -y && apt-get clean -y

# RUN apt-get install -y \    
#         python3-setuptools python3-dev \
#         python3-pip \
#         && apt-get autoremove -y && apt-get clean -y

#     RUN apt-get install -y \    
#         python3-yara \
#         python3-redis \
#         python3-zmq \
#         virtualenv \
#         libpq5 \
#         libjpeg-dev \
#         libfuzzy-dev \
#         ruby asciidoctor \
#         sqlite3 \
#         libxml2-dev \
#         libxslt1-dev \
#         zlib1g-dev \
#         && apt-get autoremove -y && apt-get clean -y

#     RUN apt-get install -y \
#         python-pip \
#         jq \
#         imagemagick \
#         && apt-get autoremove -y && apt-get clean -y


#     RUN apt-get install -y \
#         jupyter-notebook \
#         tesseract-ocr \
#         python-setuptools \
#         && apt-get autoremove -y && apt-get clean -y


    # Install MariaDB (a MySQL fork/alternative) | Server has its own container!!!
    RUN apt-get install -y \
        mariadb-client \
        #mariadb-server \
        && apt-get autoremove -y && apt-get clean -y


    # Install Apache
    RUN apt-get install -y \
        apache2 \
        apache2-doc \
        apache2-utils \
        && apt-get autoremove -y && apt-get clean -y

    # ATTENTION the part about a2enmod/a2dismod, a2ensite/a2dissite is moved to step 7.



    # Install PHP and depedencies
    # https://www.chris-shaw.com/blog/installing-php-7.2-on-debian-8-jessie-and-debian-9-stretch
    ARG PHP_VERSION=7.2
    RUN \
        apt-get update && apt-get -y install apt-transport-https lsb-release ca-certificates; \
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg; \
        sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'; \
        apt-get update && apt-get install -y \
        libapache2-mod-php${PHP_VERSION} \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-dev \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-mbstring \
        php-pear \
        php-redis \
        php-gnupg \
        php${PHP_VERSION}-gd \
        && apt-get autoremove -y && apt-get clean -y


# 3/ MISP code
# ------------
    # Set Environment Variables
    ARG VERSION
    ENV MISP_TAG=${VERSION} \
        SUDO_WWW="gosu www-data" \
        PATH_TO_MISP="/var/www/MISP"
    # Download MISP using git in the /var/www/ directory.
    # Attention: we replaced the fixed tag with a variable
    RUN \
        # Create directory
        mkdir ${PATH_TO_MISP} \
        ;chown www-data:www-data ${PATH_TO_MISP} \
        # Clone MISP Repository
        ;$SUDO_WWW git clone https://github.com/MISP/MISP.git ${PATH_TO_MISP} \
        ;cd ${PATH_TO_MISP} \
        ;[ "$MISP_TAG" != "2.4" ] && $SUDO_WWW git checkout tags/v${MISP_TAG} \
        # CakePHP and a lot of other things is included as a submodule of MISP, execute the following commands to let git fetch it:
        ;$SUDO_WWW git submodule update --init --recursive \
        # Make git ignore filesystem permission differences for submodules
        ;$SUDO_WWW git submodule foreach --recursive git config core.filemode false \
        # Make git ignore filesystem permission differences
        ;$SUDO_WWW git config core.filemode false \
        # Create a python3 virtualenv
        ;$SUDO_WWW virtualenv -p python3 ${PATH_TO_MISP}/venv

    # install Mitre's STIX and its dependencies by running the following commands:
        RUN \
            # install mixbox to accomodate the new STIX dependencies:
            $SUDO_WWW git clone https://github.com/CybOXProject/mixbox.git /var/www/MISP/app/files/scripts/mixbox \
            ;cd ${PATH_TO_MISP}/app/files/scripts/mixbox \
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/python3 setup.py install \
        # install python-maec
            ;$SUDO_WWW git clone https://github.com/MAECProject/python-maec.git /var/www/MISP/app/files/scripts/python-maec \
            ;cd ${PATH_TO_MISP}/app/files/scripts/python-maec \
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/python3 setup.py install \
        # install python-cybox
            ;$SUDO_WWW git clone https://github.com/CybOXProject/python-cybox.git /var/www/MISP/app/files/scripts/python-cybox \
            ;cd ${PATH_TO_MISP}/app/files/scripts/python-cybox \
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/python3 setup.py install \
        # install python stix
            ;$SUDO_WWW git clone https://github.com/STIXProject/python-stix.git /var/www/MISP/app/files/scripts/python-stix \
            ;cd ${PATH_TO_MISP}/app/files/scripts/python-stix \
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/python3 setup.py install \
        # install STIX2.0 library to support STIX 2.0 export:
            ;cd /var/www/MISP/cti-python-stix2 \
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/python3 setup.py install \
        # install PyMISP
            ;cd /var/www/MISP/PyMISP \
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/python3 setup.py install \
         # install pydeep
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install git+https://github.com/kbandla/pydeep.git \
            # install lief
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install https://github.com/lief-project/packages/raw/lief-master-latest/pylief-0.9.0.dev.zip \
            # install python-magic
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install python-magic \
            # install plyara
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install plyara \
        # Install Crypt_GPG and Console_CommandLine
            ;pear install ${PATH_TO_MISP}/INSTALL/dependencies/Console_CommandLine/package.xml \
            ;pear install ${PATH_TO_MISP}/INSTALL/dependencies/Crypt_GPG/package.xml



# 4/ CakePHP
# ------------
    # Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
    RUN \
        # Make composer cache happy
        mkdir /var/www/.composer \
        ;chown www-data:www-data /var/www/.composer \
        ;cd ${PATH_TO_MISP}/app \
        #;$SUDO_WWW php composer.phar self-update --stable \
        ;$SUDO_WWW php composer.phar require kamisama/cake-resque:4.1.2 \
        ;$SUDO_WWW php composer.phar config vendor-dir Vendor \
        ;$SUDO_WWW php composer.phar install \
    # Enable CakeResque with php-redis
        ;phpenmod redis \
    # Enable CakeResque with php-gnupgp
        ;phpenmod gnupg \
    # To use the scheduler worker for scheduled tasks, do the following:
        ;$SUDO_WWW cp -fa ${PATH_TO_MISP}/INSTALL/setup/config.php ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php
    # If you have multiple MISP instances on the same system, don't forget to have a different Redis per MISP instance for the CakeResque workers
    # The default Redis port can be updated in Plugin/CakeResque/Config/config.php



# # 5/ Set the permissions
# # ----------------------
    # Check if the permissions are set correctly using the following commands:
    # RUN \
    #     find /var/www/MISP -not -user www-data -exec chown www-data.www-data {} + \
    #     ;chmod -R 750 /var/www/MISP \
    #     ;chmod -R g+ws /var/www/MISP/app/tmp \ 
    #     ;chmod -R g+ws /var/www/MISP/app/files \
    #     ;chmod -R g+ws /var/www/MISP/app/files/scripts/tmp
    ##### IS DONE VIA ENTRYPONT_APACHE2.sh SCRIPT
    # At the moment all www-data commands are done as www-data, therefore this is not required.



# # 6/ Create a database and user
# # -----------------------------
#     # At the moment this will be done via misp-db container



# 7 Configure Apache
# ------------------
    # add HTTP MISP Config
    ARG sudo=""
    RUN rm /etc/apache2/sites-enabled/*;
    COPY files/etc/apache2/sites-enabled/misp.ssl /etc/apache2/sites-enabled/
    COPY files/etc/apache2/sites-enabled/misp.conf /etc/apache2/sites-enabled/
    COPY files/etc/apache2/ports.conf /etc/apache2/ports.conf
    RUN \
        chmod 640 /etc/apache2/ports.conf \
        ;chown root.root /etc/apache2/ports.conf \
        ;chmod 640 /etc/apache2/sites-available/* \
        ;chown root.root /etc/apache2/sites-available/* \
    # Configure Apache
        ;sudo a2dismod status \
        ;sudo a2enmod ssl \
        ;sudo a2enmod rewrite \
        ;sudo a2enmod headers



### 8/ Log rotation
    # MISP saves the stdout and stderr of its workers in /var/www/MISP/app/tmp/logs
    # To rotate these logs install the supplied logrotate script:
    RUN \
        sudo cp ${PATH_TO_MISP}/INSTALL/misp.logrotate /etc/logrotate.d/misp \
        ;sudo chmod 0640 /etc/logrotate.d/misp 



### 9/ MISP configuration
    # There are 4 sample configuration files in /var/www/MISP/app/Config that need to be copied
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php
    #### Is done in misp-server entrypoint script.


# #########################################
# #       END of MISP Config Part
# #########################################

# # ADD additionall modules
#     # MISP has a new pub/sub feature, using ZeroMQ. To enable it, simply run the following command
#     # ZeroMQ depends on the Python client for Redis
#     RUN \
#         pip3 install pyzmq \
#         ;pip3 install redis \
#         ;pip install pyzmq \
#         ;pip install redis \
#     # For the experimental ssdeep correlations, run the following installation:
#     # installing ssdeep
#         ;cd /usr/local/src/ \
#         ;wget http://downloads.sourceforge.net/project/ssdeep/ssdeep-2.13/ssdeep-2.13.tar.gz \
#         ;tar zxvf ssdeep-2.13.tar.gz \
#         ;cd ssdeep-2.13 \
#         ;./configure \
#         ;make    \
#         ;sudo make install \
#         ;ssdeep -h; # test \
#     #installing ssdeep_php
#         ;sudo pecl install ssdeep \
#     # 7.0 if your PHP 7.0 and you know what to do if you have a different version
#         ;for FILE in $(ls /etc/php/) \
#         do \
#             echo "extension=ssdeep.so" > /etc/php/$FILE/mods-available/ssdeep.ini; \
#             phpenmod ssdeep; \
#         done;


#########################################
#       Start of DCSO MISP Config Part

# for S/MIME
RUN sudo -u www-data mkdir /var/www/MISP/.smime; \
    sudo -u www-data chmod 500 /var/www/MISP/.smime; \
# for PGP
    sudo -u www-data mkdir /var/www/MISP/.gnupg; \
    sudo -u www-data chmod 700 /var/www/MISP/.gnupg; \
    # for local MySQL Server: delete all config files
    rm -Rf /var/lib/mysql/*;
    
# # add own mysql config
#     COPY files/etc/mysql/mariadb.conf.d/DCSO.cnf /etc/mysql/mariadb.conf.d/
#     RUN chmod -R 644 /etc/mysql/mariadb.conf.d/

# # Copy patch File for MISP Events Page with additional Analyse Column
#     COPY --chown=www-data:www-data files/var/www/MISP/app/View/Elements/Events/eventIndexTable.patch /

# Syslog Server & rsyslog
    #COPY files/etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
    #COPY files/etc/rsyslog.d/rsyslog_custom.conf /etc/rsyslog.d/

# HTML5 File uploader from http://www.matlus.com/html5-file-upload-with-progress/#codeListing6
    #COPY files/ssl_upload.html /var/www/MISP/app/webconfig/

# Postfix
# Copy files to postfix container
    COPY files/etc/postfix/* /etc/postfix/

# I create this empty file to decide is the configuration completely new or not in the entrypoint_apache.sh
    RUN touch "/var/www/MISP/app/Config/NOT_CONFIGURED"

# MISP Update and MISP Cron
    COPY --chown=www-data:www-data files/usr/local/bin/misp_update.sh /usr/local/bin/
    COPY --chown=www-data:www-data files/usr/local/bin/misp_cron.sh /usr/local/bin/

# Healthcheck
    COPY files/healthcheck.sh /
    HEALTHCHECK --interval=1m --timeout=45s --retries=3 CMD ["/healthcheck.sh"]

# Entrypoints
    COPY files/entrypoint_apache.sh /
    COPY files/entrypoint_cron.sh /
    #COPY files/entrypoint_mariadb.sh /
    #COPY files/entrypoint_monitoring.sh /
    COPY files/entrypoint_postfix.sh /
    #COPY files/entrypoint_redis.sh /
    COPY files/entrypoint_rsyslog.sh /
    COPY files/entrypoint_ssmtp.sh /
    #COPY files/entrypoint_syslog-ng.sh /
    COPY files/entrypoint_workers.sh /
    COPY files/entrypoint.sh /

# Supervisord
    ENTRYPOINT [ "/entrypoint.sh" ]

# Change Work directory
    WORKDIR /var/www/MISP


#       End of DCSO MISP Config Part
#########################################


#     Variables for Labels and Environment Variables:
ARG VENDOR="DCSO GmbH"
ARG COMPONENT="server"
ARG BUILD_DATE
ARG GIT_REPO
ARG VCS_REF
ARG RELEASE_DATE
ARG NAME="MISP-dockerized-${COMPONENT}"
ARG DESCRIPTION="This docker container is part of the DCSO MISP dockerized environment."
ARG DOCUMENTATION="https://github.com/DCSO/MISP-dockerized"
ARG AUTHOR="DCSO MISP Docker Team <misp.docker@dcso.de>"
ARG LICENSE="BSD-3-Clause"

# Environment Variables
# CMD
ENV NAME=${NAME} \
    VERSION=${VERSION} \
    RELEASE_DATE=${RELEASE_DATE} \
    SUDO_WWW=${SUDO_WWW} \
# Set locals
    # ENV LC_ALL ${LANG}
    LANGUAGE=en_US:en \
# PHP
    PHP_ETC_BASE=/etc/php/${PHP_VERSION} \
    PHP_INI=${PHP_ETC_BASE}/apache2/php.ini
#     END Variables

#########################################
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
#########################################
