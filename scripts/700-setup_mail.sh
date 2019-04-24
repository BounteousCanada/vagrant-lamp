#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Mail"

# Download binary from github
if [ ! -f /usr/local/bin/mailhog ]; then
    wget --progress=bar:force -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64

    # Make it executable
    chmod +x /usr/local/bin/mailhog
fi

if [ ! -f /usr/local/bin/mhsendmail ]; then
    wget --progress=bar:force -O /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64
    chmod +x /usr/local/bin/mhsendmail
fi

if [ ! -f /etc/init.d/mailhog ]; then
    # Make it start on reboot
    tee /etc/init.d/mailhog <<- _EOF_
#! /bin/sh

### BEGIN INIT INFO
# Provides:          mailhog
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start MailHog at boot time.
# Description:       Enable MailHog.
### END INIT INFO

PID=/var/run/mailhog.pid
LOCK=/var/lock/mailhog.lock
USER=nobody
BIN=/usr/local/bin/mailhog
DAEMONIZE_BIN=/usr/sbin/daemonize

# Carry out specific functions when asked to by the system
case "\$1" in
  start)
    echo "Starting mailhog."
    \$DAEMONIZE_BIN -p \$PID -l \$LOCK -u \$USER \$BIN
    ;;
  stop)
    if [ -f \$PID ]; then
      echo "Stopping mailhog.";
      kill -TERM \$(cat \$PID);
      rm -f \$PID;
    else
      echo "MailHog is not running.";
    fi
    ;;
  restart)
    echo "Restarting mailhog."
    if [ -f \$PID ]; then
      kill -TERM \$(cat \$PID);
      rm -f \$PID;
    fi
    \$DAEMONIZE_BIN -p \$PID -l \$LOCK -u \$USER \$BIN
    ;;
  status)
    if [ -f \$PID ]; then
      echo "MailHog is running.";
    else
      echo "MailHog is not running.";
      exit 3
    fi
    ;;
  *)
    echo "Usage: /etc/init.d/mailhog {start|stop|status|restart}"
    exit 1
    ;;
esac

exit 0
_EOF_

    tee /etc/systemd/system/mailhog.server <<- _EOF_
[Unit]
Description=MailHog Email Catcher
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mailhog
StandardOutput=journal
Restart=on-failure

[Install]
WantedBy=multi-user.target
_EOF_

    # Start it now in the background
    chmod +x /etc/init.d/mailhog
    systemctl enable mailhog
    systemctl start mailhog
fi

if [ ! -f /etc/apache2/sites-available/100-mailhog.bounteousvm.local.conf ]; then
    # Create SSL
    openssl req -x509 -nodes -newkey rsa:2048 -keyout "/etc/apache2/ssl/private/mailhog.bounteousvm.local.key" -out "/etc/apache2/ssl/cert/mailhog.bounteousvm.local.crt" -days 365 \
        -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:mailhog.bounteousvm.local")) \
        -subj "/C=CA/ST=Ontario/L=Toronto/O=Bounteous/OU=Development/CN=mailhog.bounteousvm.local"

    # Add Vhost
    tee /etc/apache2/sites-available/100-mailhog.bounteousvm.local.conf <<EOL
<VirtualHost *:8090>
  ProxyPreserveHost On
  ProxyRequests Off
  ServerName mailhog.bounteousvm.local
  ProxyPass / http://127.0.0.1:8025/
  ProxyPassReverse / http://127.0.0.1:8025/
</VirtualHost>
<VirtualHost *:443>
    ServerName  mailhog.bounteousvm.local
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:80/
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Forwarded-Proto "https"

    # SSL settings
    SSLEngine on
    SSLCertificateFile  /etc/apache2/ssl/cert/mailhog.bounteousvm.local.crt
    SSLCertificateKeyFile /etc/apache2/ssl/private/mailhog.bounteousvm.local.key
</VirtualHost>
EOL

    # Enable Vhost and reload apache
    a2ensite 100-mailhog.bounteousvm.local
    service apache2 reload
fi
