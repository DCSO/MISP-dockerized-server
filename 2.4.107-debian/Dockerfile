FROM debian:stretch-slim
ENV DEBIAN_FRONTEND noninteractive

# DCSO Required Software
RUN \
    apt-get update \
    && apt-get install -y -qq \ 
        supervisor \
        gosu \
        curl \
        rsyslog \
        bash \
        msmtp \
        apt-utils \
    && apt-get autoremove -y \
    && apt-get clean -y

#########################    START  MISP Guide

# 1/ Minimal Ubuntu install
# -------------------------

    # # Install Postfix dependency
    # RUN apt-get update \
    #     && apt-get install postfix -y -qq \
    #     && apt-get autoremove -y \
    #     && apt-get clean -y


    # 2/ Install LAMP & dependencies
    # ------------------------------
    # Install required software
    ## Installation of libfuzzy-dev is required for pydeep
    
# We removed redis-server and add redis-tools instead of these.
RUN \
    apt-get update \
    && apt-get install -y -qq \
        curl gcc git gpg-agent make python python3 openssl \
        redis-tools sudo vim zip unzip virtualenv libfuzzy-dev sqlite3 \
    && apt-get autoremove -y && apt-get clean -y

RUN \
    apt-get update \
    && apt-get install -y -qq \
        python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools \
    && apt-get autoremove -y && apt-get clean -y

    # Install MariaDB (a MySQL fork/alternative) | Server has its own container!!!
    RUN apt-get install -y -qq \
        mariadb-client \
        #mariadb-server \
        && apt-get autoremove -y && apt-get clean -y

    # Install Apache
    RUN \
        apt-get update \
        && apt-get install -y -qq \
            apache2 \
            apache2-doc \
            apache2-utils \
        && apt-get autoremove -y && apt-get clean -y
    # ATTENTION the part about a2enmod/a2dismod, a2ensite/a2dissite is moved to step 7.

    # Install PHP and depedencies
    # https://www.chris-shaw.com/blog/installing-php-7.2-on-debian-8-jessie-and-debian-9-stretch
    ARG PHP_VERSION=7.2
    RUN \
        apt-get update \
        && apt-get install -y -qq \
            apt-transport-https lsb-release ca-certificates \
        && curl -L https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg \
        && sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
        && apt-get update \
        && apt-get install -y -qq \
            libapache2-mod-php${PHP_VERSION} \
            php${PHP_VERSION} \
            php${PHP_VERSION}-common \
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
        # PHP7.2 require mpm_prefork and activate it during installation but only one mpm at the same time is allowed.
        && a2dismod mpm_event \
        && apt-get autoremove -y && apt-get clean -y


# 3/ MISP code
# ------------
    # Set Environment Variables
    ARG VERSION=2.4.nightly-debian
    ENV SUDO_WWW="gosu www-data" \
        PATH_TO_MISP="/var/www/MISP"
    # Download MISP using git in the /var/www/ directory.
    # Attention: we replaced the fixed tag with a variable
    RUN set -e \
        # Create directory
        ;mkdir ${PATH_TO_MISP} \
        ;chown www-data:www-data ${PATH_TO_MISP} \
        # Clone MISP Repository
        ;$SUDO_WWW git clone https://github.com/MISP/MISP.git ${PATH_TO_MISP} \
        ;cd ${PATH_TO_MISP} \
        ; [ "$(echo ${VERSION}| cut -d - -f 1)" != "2.4.nightly" ] && $SUDO_WWW git checkout "tags/v$(echo ${VERSION}| cut -d - -f 1)" \
        # CakePHP and a lot of other things is included as a submodule of MISP, execute the following commands to let git fetch it:
        ;$SUDO_WWW git submodule update --init --recursive \
        # Make git ignore filesystem permission differences for submodules
        ;$SUDO_WWW git submodule foreach --recursive git config core.filemode false \
        # Make git ignore filesystem permission differences
        ;$SUDO_WWW git config core.filemode false \
        # Create a python3 virtualenv
        ;$SUDO_WWW virtualenv -p python3 ${PATH_TO_MISP}/venv

    # install Mitre's STIX and its dependencies by running the following commands:
        RUN set -e \
            # install mixbox to accomodate the new STIX dependencies:
            ;$SUDO_WWW git clone https://github.com/CybOXProject/mixbox.git /var/www/MISP/app/files/scripts/mixbox \
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
        # install zmq
            ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install zmq \
        # Install Crypt_GPG and Console_CommandLine
            ;pear install ${PATH_TO_MISP}/INSTALL/dependencies/Console_CommandLine/package.xml \
            ;pear install ${PATH_TO_MISP}/INSTALL/dependencies/Crypt_GPG/package.xml



# 4/ CakePHP
# ------------
    # Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
    RUN set -e \
        # Make composer cache happy
        ;mkdir /var/www/.composer \
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
    RUN set -e \
        ;rm /etc/apache2/sites-enabled/* \
    # Configure Apache
        ;sudo a2dismod status \
        ;sudo a2enmod ssl \
        ;sudo a2enmod rewrite \
        ;sudo a2enmod headers \
### 8/ Log rotation
    # MISP saves the stdout and stderr of its workers in /var/www/MISP/app/tmp/logs
    # To rotate these logs install the supplied logrotate script:
        ;sudo cp ${PATH_TO_MISP}/INSTALL/misp.logrotate /etc/logrotate.d/misp \
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

# ADD additionall modules
    # MISP has a new pub/sub feature, using ZeroMQ. To enable it, simply run the following command
    # ZeroMQ depends on the Python client for Redis
    RUN set -e \
        ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install pyzmq \
        ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install redis \
    # For the experimental ssdeep correlations, run the following installation:
    # installing ssdeep
        ;cd /usr/local/src/ \
        ;curl -L http://downloads.sourceforge.net/project/ssdeep/ssdeep-2.13/ssdeep-2.13.tar.gz -o /usr/local/src/ssdeep-2.13.tar.gz \
        ;tar zxvf ssdeep-2.13.tar.gz \
        ;cd ssdeep-2.13 \
        ;./configure \
        ;make    \
        ;sudo make install \
        ;ssdeep -h; # test \
    #installing ssdeep_php
        ;pecl install ssdeep \
    # 7.0 if your PHP 7.0 and you know what to do if you have a different version
        ;echo "extension=ssdeep.so" > /etc/php/$PHP_VERSION/mods-available/ssdeep.ini; \
        ;phpenmod ssdeep \
        ;


#########################################
#       Start of DCSO MISP Config Part


# Mailsigning and encryption
ENV GPG_HOME="/var/www/.gnupg" \
    SMIME_HOME="/var/www/.smime"
RUN set -e  \
# for S/MIME
    ;mkdir ${SMIME_HOME} \
    ;chown -R www-data.www-data ${SMIME_HOME} \
    ;chmod -R 700 ${SMIME_HOME} \
# for PGP
    ;mkdir ${GPG_HOME} \
    ;chown -R www-data.www-data ${GPG_HOME} \
    ;chmod -R 700 ${GPG_HOME} \
    ;

# # Copy patch File for MISP Events Page with additional Analyse Column
     COPY --chown=www-data:www-data files/var/www/MISP/app/View/Elements/Events/eventIndexTable.patch /

# # Copy DCSO PyMISP Scripts
     COPY --chown=www-data:www-data files/var/www/MISP/app/files/DCSO /var/www/MISP/app/files/DCSO
     RUN set -e \
        ;$SUDO_WWW ${PATH_TO_MISP}/venv/bin/pip3 --no-cache-dir install -r /var/www/MISP/app/files/DCSO/pymisp_scripts/requirements.txt \
# I create this empty file to decide is the configuration completely new or not in the entrypoint_apache.sh
        ;touch "/var/www/MISP/app/Config/NOT_CONFIGURED" \
        ;
# HTML5 File uploader from http://www.matlus.com/html5-file-upload-with-progress/#codeListing6
    #COPY files/ssl_upload.html /var/www/MISP/app/webconfig/

# Selfwritten shellscripts
    COPY --chown=www-data:www-data files/usr/local/bin/misp_update.sh /usr/local/bin/misp_update
    COPY --chown=www-data:www-data files/usr/local/bin/misp_cron.sh /usr/local/bin/misp_cron
    COPY --chown=www-data:www-data files/usr/local/bin/misp_version.sh /usr/local/bin/misp_version
    COPY --chown=www-data:www-data files/usr/local/bin/generate_self-signed-cert.sh /usr/local/bin/generate_self-signed-cert
    COPY --chown=www-data:www-data files/usr/local/bin/generate_web_server_configuration.sh /usr/local/bin/generate_web_server_configuration
    COPY --chown=www-data:www-data files/usr/local/bin/change-pgp.sh /usr/local/bin/change-pgp

# Healthcheck
    COPY files/healthcheck.sh /
    HEALTHCHECK --interval=1m --timeout=45s --retries=3 --start-period=60s CMD ["/healthcheck.sh"]

# Entrypoints
    COPY files/entrypoint_apache.sh /
    COPY files/entrypoint_cron.sh /
    COPY files/entrypoint_rsyslog.sh /
    COPY files/entrypoint_workers.sh /
    COPY files/entrypoint.sh /

# Supervisord
    ENTRYPOINT [ "/entrypoint.sh" ]
# Change Work directory
    WORKDIR /var/www/MISP
# Expose Port
    EXPOSE 443 80

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
# Cake
    CAKE="$PATH_TO_MISP/app/Console/cake" \
# PHP
    PHP_ETC_BASE="/etc/php/$PHP_VERSION"
ENV PHP_INI=${PHP_ETC_BASE}/apache2/php.ini
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
