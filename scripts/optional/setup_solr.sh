#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup SOLR"

# Install Tomcat 9

if [ ! -f /etc/tomcat9/tomcat-users.xml ]; then
    apt-get -y install tomcat9 tomcat9-admin 2>&1
    sed -i 's|</tomcat-users>|  <role rolename="admin-gui,manager-gui"/>\n  <user username="vagrant" password="vagrant" roles="admin-gui,manager-gui"/>\n</tomcat-users>|' /etc/tomcat9/tomcat-users.xml
    service tomcat9 restart
fi

#install solr
if [ ! -d /opt/solr ]; then
    cd /opt/
    wget --progress=bar:force https://github.com/BounteousCanada/vagrant-lamp-assets/releases/download/V1.1/solr.tar.gz
    if [ -f /opt/solr.tar.gz ]; then
        tar -zxf solr.tar.gz
        chown -R tomcat:tomcat /opt/solr
        cp /opt/solr/extra/* /etc/tomcat9/Catalina/localhost/
        service tomcat9 restart
    fi
fi

if [ ! -f /etc/apache2/sites-available/100-solr.bounteousvm.local.conf ]; then
    # Create SSL
    openssl req -x509 -nodes -newkey rsa:2048 -keyout "/etc/apache2/ssl/private/solr.bounteousvm.local.key" -out "/etc/apache2/ssl/cert/solr.bounteousvm.local.crt" -days 365 \
        -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:solr.bounteousvm.local")) \
        -subj "/C=CA/ST=Ontario/L=Toronto/O=Bounteous/OU=Development/CN=solr.bounteousvm.local"

    # Add Vhost
    tee /etc/apache2/sites-available/100-solr.bounteousvm.local.conf <<EOL
<VirtualHost *:8090>
  ProxyPreserveHost On
  ProxyRequests Off
  ServerName solr.bounteousvm.local
  ProxyPass / http://127.0.0.1:8080/
  ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
<VirtualHost *:443>
    ServerName  solr.bounteousvm.local
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:80/
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Forwarded-Proto "https"

    # SSL settings
    SSLEngine on
    SSLCertificateFile  /etc/apache2/ssl/cert/solr.bounteousvm.local.crt
    SSLCertificateKeyFile /etc/apache2/ssl/private/solr.bounteousvm.local.key
</VirtualHost>
EOL

    # Enable Vhost and reload apache
    a2ensite 100-solr.bounteousvm.local
    service apache2 reload
fi

# Setup Solr Script
yes | cp -rf /vagrant/files/tools/solr.sh /usr/local/bin/solr
chmod +x /usr/local/bin/solr