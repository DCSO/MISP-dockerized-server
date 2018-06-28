#FROM debian:buster
FROM ubuntu:16.04

#     Variables:
# for Labels:
ARG VENDOR="DCSO GmbH <www.dcso.de>"
ARG NAME="server"
ARG BUILD_DATE
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
# for Installation
ARG MISP_TAG=2.4.93
#     END Variables

#########################################
LABEL org.label-schema.build-date="${BUILD_DATE}" \
        org.label-schema.name="MISP-dockerized-${NAME}" \
        org.label-schema.description="This docker container is part of the DCSO MISP dockerized environment." \
        org.label-schema.vcs-ref="${VCS_REF}" \
        org.label-schema.vcs-url="${GIT_REPO}" \
        org.label-schema.vendor="${VENDOR}" \
        org.label-schema.version="${MISP_TAG}" \
        org.label-schema.schema-version="1.0.0-rc1"

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
apt-utils \
wget \
supervisor \
gosu \
python-pip \
&& apt-get autoremove -y && apt-get clean -y

# Set locals
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

#########################    START  MISP Guide

# 1/ Minimal Ubuntu install
# -------------------------
    # Upgrade System
    RUN apt-get update -y && apt-get autoremove -y && apt-get clean -y

    # ATTENTION Postfix has its own container!


    # 2/ Install LAMP & dependencies
    # ------------------------------
    # Install required software
    RUN apt-get install -y \
        curl gcc git gnupg-agent make python python3 openssl redis-server sudo vim zip \
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
        php-crypt-gpg \
        php-dev \
        php-json \
        php-mysql \
        php-opcache \
        php-readline \
        php-redis \
        php-xml \
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

    # install Mitre's STIX and its dependencies by running the following commands:
        RUN apt-get install -y python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools
        # Upgrade
        RUN pip3 install setuptools --upgrade;
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

    # install PyMISP
    RUN cd /var/www/MISP/PyMISP; \
        sudo python3 setup.py install

    # install support for STIX 2.0 (Python 3 is required)
    RUN pip3 install stix2






# 4/ CakePHP
# ------------
    # CakePHP is included as a submodule of MISP, execute the following commands to let git fetch it:
    RUN cd /var/www/MISP; git submodule init; git submodule update;
    # Make git ignore filesystem permission differences for submodules
    RUN cd /var/www/MISP; git submodule foreach git config core.filemode false

    # Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
    RUN cd /var/www/MISP/app; sudo -u www-data php composer.phar require kamisama/cake-resque:4.1.2; \
        php composer.phar config vendor-dir Vendor; \
        php composer.phar install;

    # Enable CakeResque with php-redis
    RUN sudo phpenmod redis

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
        chown root.root /etc/apache2/ports.conf \
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
    RUN pip install pyzmq; \
        pip install redis;


    # For the experimental ssdeep correlations, run the following installation:
    # installing ssdeep
        RUN cd /usr/local/src/; wget http://downloads.sourceforge.net/project/ssdeep/ssdeep-2.13/ssdeep-2.13.tar.gz; \
        tar zxvf ssdeep-2.13.tar.gz; \
        cd ssdeep-2.13; \
        ./configure; \
        make;    \
        sudo make install;
        #ssdeep -h; # test

        #installing ssdeep_php
        RUN sudo pecl install ssdeep;

        # 7.0 if your PHP 7.0 and you know what to do if you have a different version
        RUN sudo echo "extension=ssdeep.so" > /etc/php/7.0/mods-available/ssdeep.ini; \
            sudo phpenmod ssdeep;

    # #pydeep:… Please install pydeep: pip install git+https://github.com/kbandla/pydeep.git
    RUN pip install git+https://github.com/kbandla/pydeep.git
    # #magic:… Please install python-magic: pip install python-magic.
    RUN pip install python-magic
    # #lief:… Please install lief, documentation here: https://github.com/lief-project/LIEF
    RUN pip install setuptools --upgrade; \ 
        pip install lief


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
RUN mv /etc/mysql /etc/mysql.orig; \
    mkdir /etc/mysql; \
    rm -Rf /var/lib/mysql/*;

# add own mysql config
COPY files/DCSO.cnf /etc/mysql/

# Copy PHP.ini File for PHP Config
COPY files/php.ini /etc/php/7.0/apache2/


# Environment Variables
    # CMD
    ENV CMD_MYSQL mysqld
    ENV CMD_APACHE none
    ENV CMD_REDIS "redis-server --appendonly yes"
    # Environment Variable for Proxy
    ENV HTTP_PROXY=""
    ENV HTTPS_PROXY=""
    ENV NO_PROXY="0.0.0.0"


# Entrypoints
    # CMD
    COPY files/entrypoint*.sh files/init*.sh files/healthcheck.sh /
    RUN chmod +x /*.sh
    #ENTRYPOINT [ "/entrypoint.sh" ]

# Supervisord
    # Copy Supervisord config
    COPY files/supervisord.conf /etc/supervisor/supervisord.conf
    # Execute Supervisord after start:
    CMD exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Add Healthcheck Config
HEALTHCHECK --interval=1m --timeout=45s --retries=3 CMD ["/healthcheck.sh"]


#       End of DCSO MISP Config Part
#########################################
