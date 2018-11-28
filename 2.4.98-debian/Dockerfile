FROM debian:stretch-slim


#     Variables for Labels:
ARG VENDOR="DCSO GmbH"
ARG COMPONENT="server"
ARG BUILD_DATE
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
ARG MISP_TAG=${VERSION}
ARG RELEASE_DATE
ARG NAME="MISP-dockerized-${COMPONENT}"
ARG DESCRIPTION="This docker container is part of the DCSO MISP dockerized environment."
ARG DOCUMENTATION="https://github.com/DCSO/MISP-dockerized"
ARG AUTHOR="DCSO MISP Docker Team <misp.docker@dcso.de>"
ARG LICENSE="BSD-3-Clause"
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


#       Start of MISP Config Part

# Install core components
ENV DEBIAN_FRONTEND noninteractive
#RUN apt-get install -y software-properties- && apt-get autoremove -y && apt-get clean -y

# DCSO Required Software
RUN apt-get update; apt-get install -y \ 
locales \
iputils-ping \
net-tools \
supervisor \
gosu \
wget \
#syslog-ng \
rsyslog \
&& apt-get autoremove -y && apt-get clean -y



# Set locals
ARG LANG=en_US.UTF-8
RUN locale-gen ${LANG}
ENV LANG ${LANG}
ENV LANGUAGE=en_US:en
#ENV LC_ALL ${LANG}

#########################    START  MISP Guide

# 1/ Minimal Ubuntu install
# -------------------------
    # Upgrade System
    RUN apt-get update -y && apt-get upgrade -y && apt-get autoremove -y && apt-get clean -y


    # Install Postfix dependency
    RUN apt-get update -y && apt-get install postfix -y && apt-get autoremove -y && apt-get clean -y


    # 2/ Install LAMP & dependencies
    # ------------------------------
    # Install required software
    ## Installation of libfuzzy-dev is required for pydeep
    
    RUN apt-get install -y \
        curl gcc git gnupg-agent make python3 openssl sudo vim zip \
        redis-server \
        libyara-dev \
        && apt-get autoremove -y && apt-get clean -y

    RUN apt-get install -y \    
        python3-setuptools python3-dev python3-pip python3-yara python3-redis python3-zmq virtualenv \
        libpq5 libjpeg-dev libfuzzy-dev ruby asciidoctor \
        && apt-get autoremove -y && apt-get clean -y

    RUN apt-get install -y \
        jq jupyter-notebook imagemagick tesseract-ocr \
        libxml2-dev libxslt1-dev zlib1g-dev \
        && apt-get autoremove -y && apt-get clean -y


    # Install MariaDB (a MySQL fork/alternative) | Server has its own container!!!
    RUN apt-get install -y \
        mariadb-client \
        mariadb-server \
        && apt-get autoremove -y && apt-get clean -y


    # Install Apache
    RUN apt-get install -y \
        apache2 \
        apache2-doc \
        apache2-utils \
        && apt-get autoremove -y && apt-get clean -y

    # ATTENTION the part about a2enmod/a2dismod, a2ensite/a2dissite is moved to step 7.

    # Install PHP and depedencies
    RUN apt-get install -y \
        libapache2-mod-php \
        php \
        php-cli \
        php-mbstring \
        php-dev \
        php-json \
        php-xml \
        php-mysql \
        php-opcache \
        php-readline \
        php-redis \
        php-gnupg \
        && apt-get autoremove -y && apt-get clean -y

    # ATTENTION restart is not required.






# 3/ MISP code
# ------------
    # Download MISP using git in the /var/www/ directory.
    # Attention: we replaced the fixed tag with a variable
    RUN mkdir /var/www/MISP; chown www-data:www-data /var/www/MISP;
    RUN git clone https://github.com/MISP/MISP.git /var/www/MISP; cd /var/www/MISP; git checkout tags/v${MISP_TAG};

    # Make git ignore filesystem permission differences
    RUN cd /var/www/MISP; git config core.filemode false;

    # CakePHP and a lot of other things is included as a submodule of MISP, execute the following commands to let git fetch it:
    RUN cd /var/www/MISP; git submodule init; git submodule update;
    # Make git ignore filesystem permission differences for submodules
    RUN cd /var/www/MISP; git submodule foreach git config core.filemode false

    # install Mitre's STIX and its dependencies by running the following commands:
        RUN apt-get install -y python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools
        # Upgrade
        #RUN pip3 install setuptools --upgrade;
        # install python-cybox
        RUN cd /var/www/MISP/app/files/scripts; \
            git clone https://github.com/CybOXProject/python-cybox.git; \
            cd python-cybox; python3 setup.py install;
        # install python stix
        RUN cd /var/www/MISP/app/files/scripts; \
            git clone https://github.com/STIXProject/python-stix.git; \
            cd python-stix; python3 setup.py install;
        # install mixbox to accomodate the new STIX dependencies:
        RUN cd /var/www/MISP/app/files/scripts; \
            git clone https://github.com/CybOXProject/mixbox.git; \
            cd mixbox; python3 setup.py install;
        # install python-maec
        RUN cd /var/www/MISP/app/files/scripts; \
            git clone https://github.com/MAECProject/python-maec.git; \
            cd mixbox; python3 setup.py install;

    
    # install PyMISP
    # pymisp:… Please install pymisp: pip install pymisp
    #RUN pip install pymisp
    RUN cd /var/www/MISP/PyMISP; \
        python3 setup.py install;

    # install support for STIX 2.0 (Python 3 is required)
    RUN pip3 install stix2






# 4/ CakePHP
# ------------
    # Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
    RUN cd /var/www/MISP/app; \
        php composer.phar require kamisama/cake-resque:4.1.2; \
        php composer.phar config vendor-dir Vendor; \
        php composer.phar install;

    # Enable CakeResque with php-redis
    RUN phpenmod redis

    # To use the scheduler worker for scheduled tasks, do the following:
    RUN cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php
    # If you have multiple MISP instances on the same system, don't forget to have a different Redis per MISP instance for the CakeResque workers
    # The default Redis port can be updated in Plugin/CakeResque/Config/config.php




# 5/ Set the permissions
# ----------------------
    # Check if the permissions are set correctly using the following commands:
    RUN chown -R www-data:www-data /var/www/MISP; \
        chmod -R 750 /var/www/MISP; \
        chmod -R g+ws /var/www/MISP/app/tmp; \ 
        chmod -R g+ws /var/www/MISP/app/files; \
        chmod -R g+ws /var/www/MISP/app/files/scripts/tmp;






# 6/ Create a database and user
# -----------------------------
    # At the moment this will be done via entypoint_mariadb.sh script


# 7 Configure Apache
# ------------------
    # add HTTP MISP Config
    RUN rm /etc/apache2/sites-available/*; rm /etc/apache2/sites-enabled/*;
    COPY files/misp* /etc/apache2/sites-enabled/
    COPY files/ports.conf /etc/apache2/ports.conf
    RUN chmod 640 /etc/apache2/ports.conf; \
        chown root.root /etc/apache2/ports.conf; \
        chmod 640 /etc/apache2/sites-enabled/*; \
        chown root.root /etc/apache2/sites-enabled/*
    # Configure Apache
    RUN sudo a2dismod status; \
        sudo a2enmod ssl; \
        sudo a2enmod rewrite; \
        sudo a2enmod headers;




### 8/ Log rotation
    # MISP saves the stdout and stderr of its workers in /var/www/MISP/app/tmp/logs
    # To rotate these logs install the supplied logrotate script:
    RUN sudo cp /var/www/MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp






### 9/ MISP configuration
    # There are 4 sample configuration files in /var/www/MISP/app/Config that need to be copied
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php
    # RUN sudo -u www-data cp -a /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php
    #### WILL BE DONE IN MISP_ROBOT





### 5/ Set the permissions
    # Check if the permissions are set correctly using the following commands:
    RUN chown -R www-data:www-data /var/www/MISP; \
    chmod -R 750 /var/www/MISP; \
    chmod -R g+ws /var/www/MISP/app/tmp; \ 
    chmod -R g+ws /var/www/MISP/app/files; \
    chmod -R g+ws /var/www/MISP/app/files/scripts/tmp;







#       END of MISP Config Part
#########################################

# ADD additionall modules
    # MISP has a new pub/sub feature, using ZeroMQ. To enable it, simply run the following command
    # ZeroMQ depends on the Python client for Redis
    RUN pip3 install pyzmq; \
        pip3 install redis;
    # RUN pip install pyzmq; \
    #     pip install redis;


    # For the experimental ssdeep correlations, run the following installation:
    # installing ssdeep
        RUN cd /usr/local/src/; \
            wget http://downloads.sourceforge.net/project/ssdeep/ssdeep-2.13/ssdeep-2.13.tar.gz; \
            tar zxvf ssdeep-2.13.tar.gz; \
            cd ssdeep-2.13; \
            ./configure; \
            make;    \
            sudo make install; \
            ssdeep -h; # test

        #installing ssdeep_php
        RUN sudo pecl install ssdeep;

        # 7.0 if your PHP 7.0 and you know what to do if you have a different version
        RUN for FILE in $(ls /etc/php/); \
            do echo "extension=ssdeep.so" > /etc/php/$FILE/mods-available/ssdeep.ini; \
            phpenmod ssdeep; \
            done;



    # RUN \
    #     # pymisp:… Please install pymisp: pip install pymisp
    #     pip install pymisp \
    #     # #pydeep:… Please install pydeep: pip install git+https://github.com/kbandla/pydeep.git
    #     pip install git+https://github.com/kbandla/pydeep.git; \
    #     # #magic:… Please install python-magic: pip install python-magic.
    #     pip install python-magic; \
    #     # #lief:… Please install lief, documentation here: https://github.com/lief-project/LIEF
    #     pip install setuptools --upgrade; \ 
    #     pip install lief; \



    RUN \
        # pymisp:… Please install pymisp: pip install pymisp
        pip3 install pymisp; \
        # #pydeep:… Please install pydeep: pip install git+https://github.com/kbandla/pydeep.git
        pip3 install git+https://github.com/kbandla/pydeep.git; \
        # #magic:… Please install python-magic: pip install python-magic.
        pip3 install python-magic; \
        # #lief:… Please install lief, documentation here: https://github.com/lief-project/LIEF
        pip3 install setuptools --upgrade; \
        pip3 install lief; \
        # # Install maec libraries for STIX
        pip3 install maec


#########################################
#       Start of DCSO MISP Config Part

# for S/MIME
RUN sudo -u www-data mkdir /var/www/MISP/.smime; \
    sudo -u www-data chmod 500 /var/www/MISP/.smime;
# for PGP
RUN sudo -u www-data mkdir /var/www/MISP/.gnupg; \
    sudo -u www-data chmod 700 /var/www/MISP/.gnupg;
    
# for local MySQL Server:
    # delete all config files
# RUN mv /etc/mysql /etc/mysql.orig; \
#     mkdir /etc/mysql; 
RUN rm -Rf /var/lib/mysql/*;
    
    # add own mysql config
COPY files/DCSO.cnf /etc/mysql/mariadb.conf.d/
RUN chmod -R 644 /etc/mysql/mariadb.conf.d/

# Copy patch File for MISP Events Page with additional Analyse Column
COPY files/var/www/MISP/app/View/Elements/Events/eventIndexTable.patch /

# Syslog Server & rsyslog
COPY files/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
COPY files/rsyslog_custom.conf /etc/rsyslog.d/

# Add cron file
COPY files/cron.sh /

# HTML5 File uploader from http://www.matlus.com/html5-file-upload-with-progress/#codeListing6
COPY files/ssl_upload.html /var/www/MISP/app/webconfig/

# Postfix
# Copy files to postfix container
COPY files/postfix/* /etc/postfix/

# I create this empty file to decide is the configuration completely new or not in the entrypoint_apache.sh
RUN touch "/var/www/MISP/app/Config/NOT_CONFIGURED"

# Environment Variables
    # CMD
    ENV CMD_MYSQL mysqld
    ENV CMD_APACHE none
    ENV CMD_REDIS "redis-server --appendonly yes"
    # Version + Name
    ENV NAME ${NAME}
    ENV VERSION ${VERSION}
    ENV RELEASE_DATE ${RELEASE_DATE}
    # Environment Variable for Proxy
    ENV HTTP_PROXY=""
    ENV HTTPS_PROXY=""
    ENV NO_PROXY="0.0.0.0"

    # POSTFIX
        # Hostname for the Mailserver
        ENV HOSTNAME=misp
        # Domain for Outgoing Mail
        ENV DOMAIN=example.com
        # Sender for local postfix outgoing Mails
        ENV SENDER_ADDRESS=admin@example.com
        # Relahost to Send Mails
        ENV RELAYHOST=smtp.example.local:587
        # RELAY User and Password
        ENV RELAY_USER=misp
        ENV RELAY_PASSWORD=ChangeMe
        # Allow only MISP Docker Container Access
        ENV DOCKER_NETWORK=192.168.47.0/28
        # You need to get more postfix output for a specified host normally the relayhost or misp-server
        ENV DEBUG_PEER=none




# Entrypoints
    # CMD
    COPY files/entrypoint*.sh files/healthcheck.sh /
    RUN chmod +x /*.sh

# Supervisord
    # Copy Supervisord config
    COPY files/supervisord.conf /etc/supervisor/supervisord.conf
    # Execute Supervisord after start:
    CMD exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Add Healthcheck Config
HEALTHCHECK --interval=1m --timeout=45s --retries=3 CMD ["/healthcheck.sh"]


#       End of DCSO MISP Config Part
#########################################
