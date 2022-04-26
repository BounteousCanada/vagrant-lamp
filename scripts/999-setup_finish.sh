#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Finish"

# Clean
apt-get -y upgrade && apt-get -y clean autoclean && apt-get -y autoremove

# Restart Services
service apache2 restart
service varnish restart
for f in /etc/profile.d/*-aliases.sh; do source $f; done
phpRestart
