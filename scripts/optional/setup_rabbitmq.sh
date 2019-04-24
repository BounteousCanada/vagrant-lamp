#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup RabbitMQ"

# Install RabbitMq

if [ ! -f /etc/rabbitmq/rabbitmq-env.conf ]; then
    apt-get install -y rabbitmq-server 2>&1
    rabbitmq-plugins enable rabbitmq_management
    echo "[{rabbit, [{loopback_users, []}]}]." >> /etc/rabbitmq/rabbitmq.config
    service rabbitmq-server restart
fi

if [ ! -f /etc/apache2/sites-available/100-rabbitmq.bounteousvm.local.conf ]; then
    # Create SSL
    openssl req -x509 -nodes -newkey rsa:2048 -keyout "/etc/apache2/ssl/private/rabbitmq.bounteousvm.local.key" -out "/etc/apache2/ssl/cert/rabbitmq.bounteousvm.local.crt" -days 365 \
        -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:rabbitmq.bounteousvm.local")) \
        -subj "/C=CA/ST=Ontario/L=Toronto/O=Bounteous/OU=Development/CN=rabbitmq.bounteousvm.local"

    # Add Vhost
    tee /etc/apache2/sites-available/100-rabbitmq.bounteousvm.local.conf <<EOL
<VirtualHost *:8090>
  ProxyPreserveHost On
  ProxyRequests Off
  ServerName rabbitmq.bounteousvm.local
  ProxyPass / http://127.0.0.1:15672/
  ProxyPassReverse / http://127.0.0.1:15672/
</VirtualHost>
<VirtualHost *:443>
    ServerName  rabbitmq.bounteousvm.local
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:80/
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Forwarded-Proto "https"

    # SSL settings
    SSLEngine on
    SSLCertificateFile  /etc/apache2/ssl/cert/rabbitmq.bounteousvm.local.crt
    SSLCertificateKeyFile /etc/apache2/ssl/private/rabbitmq.bounteousvm.local.key
</VirtualHost>
EOL

    # Enable Vhost and reload apache
    a2ensite 100-rabbitmq.bounteousvm.local
    service apache2 reload
fi