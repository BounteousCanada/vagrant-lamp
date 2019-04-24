#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Apache"

# Setup Apache
if ! [ -x "$(command -v apache2)" ]; then
    apt-get install -y apache2 2>&1
    a2dismod mpm_prefork mpm_worker
    a2enmod rewrite actions ssl headers proxy_fcgi proxy_http proxy_balancer

    # Change Listen Port
    sed -i.bak 's/Listen 80$/Listen 8090/' /etc/apache2/ports.conf

    # Change user and groups to vagrant
    sed -i.bak 's/www-data$/vagrant/' /etc/apache2/envvars

    # Remove default ssl conf
    if [ -f /etc/apache2/sites-available/default-ssl.conf ]; then
        rm /etc/apache2/sites-available/default-ssl.conf
    fi

    # Create SSL default directories
    mkdir -p /etc/apache2/ssl/{private,cert}

    # Restart to apply changes
    service apache2 restart
fi

# Setup VHOST Script
yes | cp -rf /vagrant/files/tools/vhost.sh /usr/local/bin/vhost
chmod +x /usr/local/bin/vhost
