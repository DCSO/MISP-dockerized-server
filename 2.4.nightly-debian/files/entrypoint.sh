#!/bin/sh

# Activate rsyslog and postfix only if it should be
if [ "$POSTFIX_ENABLE" = "true" ]
then
POSTFIX="[program:postfix]
command=/entrypoint_postfix.sh
autorestart=true"
LOGGING="[program:rsyslog]
command=/entrypoint_rsyslog.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true"
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

[program:apache2]
command=/entrypoint_apache.sh
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:cron]
command=gosu www-data /entrypoint_cron.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true

${LOGGING}

${POSTFIX}

[program:workers]
command=gosu www-data /entrypoint_workers.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true

EOF

# start supervisord
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf