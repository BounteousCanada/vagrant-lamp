#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Tools"

# Setup Composer
if [ ! -f /usr/local/bin/composer ]; then
    echo "Setup Composer."
    cd /tmp
    php=/opt/phpfarm/inst/php-$(ls -1 /opt/phpfarm/inst/ | grep php | tail -n1 | cut -d'-' -f2)/bin/php;
    wget -O composer-setup.php https://getcomposer.org/installer
    ${php} composer-setup.php --1
    ${php} -r "unlink('composer-setup.php');"
    mv composer.phar /usr/local/bin/composer
    echo "Composer moved to: /usr/local/bin/composer"
    chmod +x /usr/local/bin/composer
fi

# Pestle
echo "Setup Pestle."
curl -sL -o /usr/local/bin/pestle http://pestle.pulsestorm.net/pestle.phar
chmod +x /usr/local/bin/pestle

# Set up n98 for M1, M2 and automatic selection based on platform in use
if [ ! -f /usr/local/bin/n98 ] || [ ! -f /usr/local/bin/n98-1 ] || [ ! -f /usr/local/bin/n98-2 ]; then
    echo "Setup n98-magerun."
    cd /tmp
    rm -f n98-magerun*

    wget --progress=bar:force https://files.magerun.net/n98-magerun.phar
    mv n98-magerun.phar /usr/local/bin/n98-1
    chmod +x /usr/local/bin/n98-1

    wget --progress=bar:force https://files.magerun.net/n98-magerun2.phar
    mv n98-magerun2.phar /usr/local/bin/n98-2
    chmod +x /usr/local/bin/n98-2

    cp /vagrant/files/tools/n98 /usr/local/bin/n98
    chmod +x /usr/local/bin/n98

    if [ ! -d /usr/local/share/n98-magerun/modules ]; then
      mkdir /usr/local/share/n98-magerun/
      mkdir /usr/local/share/n98-magerun/modules
    fi
    cd /usr/local/share/n98-magerun/modules
    git clone https://github.com/gwillem/magevulndb.git

    if [ ! -d /usr/local/share/n98-magerun2/modules ]; then
      mkdir /usr/local/share/n98-magerun2/
      mkdir /usr/local/share/n98-magerun2/modules
    fi
    cd /usr/local/share/n98-magerun2/modules
    git clone https://github.com/gwillem/magevulndb.git

    cd /tmp
fi

# Bash completion for Magento CLI
echo "Setup bash completion for Magento CLI."
curl -o /etc/bash_completion.d/magento2-bash-completion https://raw.githubusercontent.com/yvoronoy/magento2-bash-completion/master/magento2-bash-completion
source /etc/bash_completion.d/magento2-bash-completion

# Setup modman
if [ ! -f /usr/local/bin/modman ]; then
    echo "Setup modman."
    cd /tmp
    bash < <(curl -s -L https://raw.github.com/colinmollenhour/modman/master/modman-installer)
    mv ~/bin/modman /usr/local/bin/modman
    chmod +x /usr/local/bin/modman
fi

# Setup PHPUnit
if [ ! -f /usr/local/bin/phpunit ]; then
    echo "Setup PHPUnit."
    cd /tmp
    wget --progress=bar:force https://phar.phpunit.de/phpunit.phar
    mv phpunit.phar /usr/local/bin/phpunit
    chmod +x /usr/local/bin/phpunit
fi
