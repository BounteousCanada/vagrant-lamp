#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Environment"

# Create backup folders for mysql and web config
mkdir -p /srv/backup/mysql
mkdir -p /srv/backup/webconfig

# Create folder for mysql data
mkdir -p /srv/mysql/data

# Create folder for php builds
mkdir -p /vagrant/files/php/builds

# Check Box Version
if [ "$(lsb_release -sr)" != "18.04" ] ; then
    set +x
    text=$(sed "s|###version###|$(lsb_release -sr)|g" /vagrant/files/upgrade.txt);
    echo -e "$text"
    exit 1
fi

apt-get update

# Install git, tig, htop, smem, strace, lynx and dos2unix
apt-get install -y git tig htop smem strace lynx 2>&1

# Copy bash aliases for all users
cp /vagrant/files/aliases/* /etc/profile.d/

# Next line needed so that root will have access to these aliases
if [ ! -f /root/.bash_aliases ] || [ $(grep -c "for f in /etc/profile.d/\*aliases.sh; do source \$f; done" /root/.bash_aliases) -eq 0 ] ; then
    echo 'for f in /etc/profile.d/*-aliases.sh; do source $f; done' >> /root/.bash_aliases
fi

# Setup PHP compile pre-requisites
apt-get install -y build-essential libbz2-dev libxpm-dev libmcrypt-dev language-pack-en \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev libfreetype6-dev daemonize libzip-dev libmagickwand-dev 2>&1

# Fix for Curl directory errors on earier versions of PHP
if [ ! -d /usr/include/curl ]; then
    sudo ln -s  /usr/include/x86_64-linux-gnu/curl  /usr/include/curl
fi

# Workaround to allow custom scripts added to path with sudo
if ! grep -q "^#Defaults[[:blank:]]*secure_path" /etc/sudoers ; then
    sed -i 's/^Defaults[[:blank:]]*secure_path/#Defaults       secure_path/' /etc/sudoers
fi

# Enable autocompletion for root
if [ $(grep -c "#Vagrant-Autocomplete" /root/.bashrc ) -eq 0 ] ; then
    cat <<EOL >> /root/.bashrc
#Vagrant-Autocomplete
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOL
fi