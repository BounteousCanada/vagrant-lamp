#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Redis"

# Setup Redis
apt-get install -y redis-server 2>&1

#setup redis script
yes | cp -rf /vagrant/files/tools/redis.sh /usr/local/bin/redis
chmod +x /usr/local/bin/redis

if [ ! -f /etc/redis/redis-default.conf ]; then
    cp /vagrant/files/redis-default.conf /etc/redis/redis-default.conf
fi
