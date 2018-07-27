#!/bin/bash
set -e

function check_and_link_error(){
    [ -e $1 ] && rm $1;
    ln -s /dev/stderr $1
}
function check_and_link_out(){
    [ -e $1 ] && rm $1;
    ln -s /dev/stdout $1
}
# For Logfiles
## APACHE2
check_and_link_out /var/log/apache2/access.log
check_and_link_out /var/log/apache2/other_vhosts_access.log
check_and_link_error /var/log/apache2/error.log
## MISP LOGS
#check_and_link_error /var/www/MISP/app/tmp/logs/debug.log
check_and_link_error /var/www/MISP/app/tmp/logs/resque-scheduler-error.log
check_and_link_error /var/www/MISP/app/tmp/logs/error.log
check_and_link_error /var/www/MISP/app/tmp/logs/resque-worker-error.log
check_and_link_out /var/www/MISP/app/tmp/logs/resque-$(date +%Y-%m-%d).log
check_and_link_out /var/www/MISP/app/tmp/logs/resque-scheduler-$(date +%Y-%m-%d).log


function init_pgp(){
    echo "####################################"
    echo "PGP Key exists and copy it to MISP webroot"
    echo "####################################"

    # Copy public key to the right place
    sudo -u www-data sh -c "cp /var/www/MISP/.gnupg/public.key /var/www/MISP/app/webroot/gpg.asc"
    ### IS DONE VIA ANSIBLE: # And export the public key to the webroot
    ### IS DONE VIA ANSIBLE: #sudo -u www-data sh -c "gpg --homedir /var/www/MISP/.gnupg --export --armor $SENDER_ADDRESS > /var/www/MISP/app/webroot/gpg.asc"
}

function init_smime(){
    echo "####################################"
    echo "S/MIME Cert exists and copy it to MISP webroot"
    echo "####################################"
    ### Set permissions
    chown www-data:www-data /var/www/MISP/.smime
    chmod 500 /var/www/MISP/.smime
    ## Export the public certificate (for Encipherment) to the webroot
    sudo -u www-data sh -c "cp /var/www/MISP/.smime/cert.pem /var/www/MISP/app/webroot/public_certificate.pem"
    #Due to this action, the MISP users will be able to download your public certificate (for Encipherment) by clicking on the footer
    ### Set permissions
    #chown www-data:www-data /var/www/MISP/app/webroot/public_certificate.pem
    sudo -u www-data sh -c "chmod 440 /var/www/MISP/app/webroot/public_certificate.pem"
}

function init_apache() {
    echo "####################################"
    echo "started Apache2 with cmd: '$CMD_APACHE'"
    echo "####################################"
    # Apache gets grumpy about PID files pre-existing
    rm -f /run/apache2/apache2.pid
    # start Workers for MISP
    su -s /bin/bash -c "/var/www/MISP/app/Console/worker/start.sh" www-data

    #exec apache2 -DFOREGROUND
    /usr/sbin/apache2ctl -DFOREGROUND -E /dev/stderr $1
}

# if secring.pgp exists execute init_pgp
[ -f "/var/www/MISP/.gnupgp/public.key" ] && init_pgp
# If certificate exists execute init_smime
[ -f "/var/www/MISP/.smime/cert.pem" ] && init_smime


[ "$CMD_APACHE" != "none" ] && init_apache $CMD_APACHE
[ "$CMD_APACHE" == "none" ] && init_apache