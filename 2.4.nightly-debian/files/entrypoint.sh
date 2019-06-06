#!/bin/sh
set -eu

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

[program:rsyslog]
command=/entrypoint_rsyslog.sh
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true

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