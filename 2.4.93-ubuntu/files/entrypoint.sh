#!/bin/sh

if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "misp-server" ]; then
DB="[program:db]
command=/entrypoint_mariadb.sh
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0"
fi

if [ "$REDIS_FQDN" = "localhost" ] || [ -z "$REDIS_FQDN" ] || [ "$REDIS_FQDN" = "misp-server" ]; then
REDIS="[program:redis]
command=/entrypoint_redis.sh
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0"
fi

# write supervisord configuration
cat << EOF > /etc/supervisor/supervisord.conf
[supervisord]
nodaemon=true
user=root
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

${DB}

[program:apache2]
command=/entrypoint_apache.sh
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

${REDIS}

[program:rsyslog]
command=/entrypoint_rsyslog.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true

[program:workers]
command=/entrypoint_workers.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true

EOF
# start supervisord
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf