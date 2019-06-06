#!/bin/sh
set -eu

# http://apetec.com/support/GenerateSAN-CSR.htm
# https://github.com/openssl/openssl/issues/3536

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[GENERATE_SELF_SIGNED_CERT]${NC}"
MISP_FQDN=${MISP_FQDN:-"$(hostname)"}
# SSL
SSL_CERT="/etc/apache2/ssl/cert.pem"
SSL_KEY="/etc/apache2/ssl/key.pem"
SSL_PID_CERT_CREATER="/etc/apache2/ssl/SSL_create.pid"
OPENSSL_CONFIG="/etc/apache2/ssl/openssl.cnf"

# Functions
echo (){
    command echo "$STARTMSG $*"
}

# Environment Parameter
    #




#
#   MAIN
#



echo "... create_ssl_cert | Create SSL certificate..."

# Create Openssl Config
cat << EOF > "$OPENSSL_CONFIG"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
commonName = ${MISP_FQDN}

[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
authorityKeyIdentifier      = issuer:always

[alt_names]
DNS.1 = ${MISP_FQDN}
DNS.2 = localhost
DNS.3 = misp-server
IP.1 = 127.0.0.1
#IP.2 = 

EOF


# If a valid SSL certificate is not already created for the server, create a self-signed certificate:
while [ -f "$SSL_PID_CERT_CREATER.proxy" ]
do
    echo "... ... $(date +%T) -  misp-proxy container create currently the certificate. misp-server wait until misp-proxy is finished."
    sleep 5
done


# Create Certificate
if [ ! -f "$SSL_CERT" ] && [ ! -f "$SSL_KEY" ]
then
    touch "${SSL_PID_CERT_CREATER}.server" 
    echo "Create SSL Certificate..." 
    openssl req -x509 -newkey rsa:4096 -keyout "$SSL_KEY" -out "$SSL_CERT" -days 365 -sha256 -nodes -config openssl.cnf -extensions v3_req
    cat /etc/apache2/ssl/cert.pem >> /etc/ssl/certs/ca-certificates.crt
    rm "${SSL_PID_CERT_CREATER}.server"
    echo "... create_ssl_cert | Create SSL certificate...finished"
else
    echo "... create_ssl_cert | Create SSL certificate is not required."
fi
