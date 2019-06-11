#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup PHP"


function setup_xdebug() {
    cd /usr/lib
    if [ -d /usr/lib/xdebug ]; then
        rm -rf xdebug
    fi
    git clone git://github.com/xdebug/xdebug.git
    cd xdebug

    if [[ $1 == *"5.5"* ]] ; then
        git checkout xdebug_2_4
    elif [[ $1 == *"5.6"* ]] ; then
        git checkout xdebug_2_5
    fi

    /opt/phpfarm/inst/php-$1/bin/phpize
    ./configure --with-php-config=/opt/phpfarm/inst/php-$1/bin/php-config
    make -j$(nproc) && make install
}

function setup_imagick() {
    wget --progress=bar:force -O imagick.tgz http://pecl.php.net/get/imagick
    tar xvzf imagick.tgz
    cd imagick-*
    /opt/phpfarm/inst/php-$1/bin/phpize

    ./configure --with-php-config=/opt/phpfarm/inst/php-$1/bin/php-config
    make -j$(nproc) && make install
}

function setup_apcu() {
    cd /usr/lib
    if [ -d /usr/lib/apcu ]; then
        rm -rf apcu
    fi
    git clone git://github.com/krakjoe/apcu.git
    cd apcu

    if [[ $1 == *"5.5"* ]] || [[ $1 == *"5.6"* ]] ; then
        git checkout PHP5
    else
        git  checkout v5.1.16
    fi

    /opt/phpfarm/inst/php-$1/bin/phpize
    ./configure --with-php-config=/opt/phpfarm/inst/php-$1/bin/php-config
    make -j$(nproc) && make install
}

function setup_openssl_legacy() {

    # Build openssl 1.0.2 for php 5.X
    mkdir /usr/lib/openssl-1.0.2
    cd /tmp
    git clone https://github.com/openssl/openssl.git
    cd openssl
    git checkout OpenSSL_1_0_2-stable
    ./config -fPIC shared --prefix=/usr/lib/openssl-1.0.2
    make -j$(nproc) && make install

    # Build curl with openssl 1.0.2
    cd /tmp
    git clone https://github.com/curl/curl.git
    cd curl
    ./buildconf
    export PKG_CONFIG_PATH=/usr/lib/openssl-1.0.2/lib/pkgconfig/
    ./configure --with-ssl --prefix=/usr/lib/openssl-1.0.2
    make -j$(nproc) && make install
}

function setup_phpfarm() {
    cd /opt
    if [ ! -d /opt/phpfarm ]; then
        git clone https://github.com/fpoirotte/phpfarm.git phpfarm
    fi

    if [[ ! -e /opt/phpfarm/custom ]]; then
        sudo mkdir -p /opt/phpfarm/custom
    fi

    # Copy custom options and ini files
    cp -a /vagrant/files/php/custom/* /opt/phpfarm/custom/

    # Setup auto-complete for switch-phpfarm
    cp /opt/phpfarm/src/phpfarm.autocomplete /etc/bash_completion.d/phpfarm
}

function setup_php() {
    source /vagrant/files/config_php.sh

    # Remove any php version not currently shown in config_php.sh
    for installed in $(ls -d /opt/phpfarm/inst/php-* | cut -d'/' -f5 | cut -d'-' -f2-); do
        expected=0;
        for i in "${config_php[@]}"; do
            arr=(${i// / })
            if [ ${installed} == ${arr[0]} ]; then
                expected=1
            fi
        done;
        if [ ${expected} == 0 ]; then
            # Remove unrequired php
            if [ -f /opt/phpfarm/inst/php-${installed}/bin/php ]; then
                echo "Removing PHP ${installed}"
                rm -Rf /opt/phpfarm/inst/php-${installed}
            fi
            for shortname in $(ls -d /etc/init.d/php-* | cut -d'/' -f4 | cut -d'-' -f2-); do
                echo "testing ${shortname}:"
                if grep -q "php-${installed}" /etc/init.d/php-${shortname} ; then
                    echo "Removing PHP init file php-${shortname}"
                    /etc/init.d/php-${shortname} stop || true

                    # This next bit is to ensure that no process keeps the listening port occupied
                    prefix=$(cat /etc/init.d/php-${shortname} | grep 'prefix=/opt/phpfarm' | cut -d'=' -f2)
                    conf=$(cat /etc/init.d/php-${shortname} | grep 'php_fpm_CONF=' | cut -d'}' -f2)
                    processes=$(ps aux | grep $prefix$conf | tr -s ' ' | cut -d ' ' -f2)
                    echo "Processes to kill: ${processes}"
                    kill ${processes} || true

                    rm /etc/init.d/php-${shortname}
                fi
            done
        fi
    done;

    # Add new versions of PHP 
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpVersion=${arr[0]}
        phpAlias=${arr[1]}
        phpPort=${arr[2]}
        phpBuild=${arr[3]}

        #Install legacy openssl if needed (PHP 5.X)
        if [ ${phpVersion:0:1} == 5 ] && [ ! -d /usr/lib/openssl-1.0.2 ]; then
           setup_openssl_legacy
        fi

        if [ ! -f /opt/phpfarm/inst/php-${phpVersion}/bin/php ]; then
            # Attempt to download from vagrant-lamp-assets repo if available
            if [ ${phpBuild} == 'false' ] && [ ! -f /vagrant/files/php/builds/php-${phpVersion}.tar.gz ]; then
                echo "Attempting to download php-${phpVersion}.tar.gz"
                if [[ `wget -S -O /vagrant/files/php/builds/php-${phpVersion}.tar.gz https://github.com/BounteousCanada/vagrant-lamp-assets/releases/download/V1.1/php-${phpVersion}.tar.gz  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
                    echo "Successfully downloaded php-${phpVersion}.tar.gz"
                else
                    rm -f /vagrant/files/php/builds/php-${phpVersion}.tar.gz
                    echo "Error downloading php-${phpVersion}.tar.gz"
                fi
            fi

            # Build from source if build is true, or prebuilt not available
            if [ ${phpBuild} == 'true' ] || [ ! -f /vagrant/files/php/builds/php-${phpVersion}.tar.gz ] ; then
                cd /opt/phpfarm/src

                if [ ${phpVersion:0:1} == 5 ]; then
                    export PKG_CONFIG_PATH=/usr/lib/openssl-1.0.2/lib/pkgconfig/
                fi

                ./main.sh ${phpVersion}
                setup_xdebug ${phpVersion}
                setup_imagick ${phpVersion}
                setup_apcu ${phpVersion}

                if [ ${phpVersion:0:1} == 5 ]; then
                    export PKG_CONFIG_PATH=
                fi
             else # Extract prebuilt version
                cd /opt/phpfarm/inst
                tar -zxf /vagrant/files/php/builds/php-${phpVersion}.tar.gz

                # Reset php .conf so port can be reconfigured
                if [ ${phpVersion:0:1} == 5 ]; then
                    rm /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf
                else
                    rm /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.d/www.conf
                fi
             fi
        fi

        # Setup php-fpm configuration
        if [ ${phpVersion:0:1} == 5 ]; then
            php_config_suffix_escaped="\/etc\/php-fpm.conf"
            if [ ! -f /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf ]; then
                cp /vagrant/files/php/php-fpm-xxx.conf /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf
                sed -i "s/###phpVersion###/${phpVersion}/g"    /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf
                sed -i "s/###phpAlias###/${phpAlias}/g"    /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf
                sed -i "s/###phpPort###/${phpPort}/g"    /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf
            fi
        else
            php_config_suffix_escaped="\/etc\/php-fpm.d\/www.conf"
            if [ ! -f /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf ]; then
                cp /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf.default /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.conf
            fi
            if [ ! -f /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.d/www.conf ]; then
                cp /vagrant/files/php/php-fpm-xxx.conf /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.d/www.conf
                sed -i "s/###phpVersion###/${phpVersion}/g"    /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.d/www.conf
                sed -i "s/###phpAlias###/${phpAlias}/g"    /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.d/www.conf
                sed -i "s/###phpPort###/${phpPort}/g"    /opt/phpfarm/inst/php-${phpVersion}/etc/php-fpm.d/www.conf
            fi
        fi

        # Create init.d script
        if [ ! -f /etc/init.d/php-${phpAlias} ]; then
            cp /vagrant/files/php/php-init.d-xxx.sh /etc/init.d/php-${phpAlias}
            sed -i "s/###phpVersion###/${phpVersion}/g" /etc/init.d/php-${phpAlias}
            sed -i "s/###php_config_suffix###/${php_config_suffix_escaped}/g" /etc/init.d/php-${phpAlias}
            chmod +x /etc/init.d/php-${phpAlias}
            update-rc.d php-${phpAlias} defaults
        fi

        # Overwrite php.ini from files/php/phpfarm
        iniTarget="/opt/phpfarm/inst/php-${phpVersion}/etc/php.ini"
        iniFound=""
        for suffix in "" "-${phpVersion:0:1}" "-${phpVersion:0:3}" "-${phpVersion:0:5}" "-${phpVersion}"; do
            custom="/vagrant/files/php/custom/php$suffix.ini"
            if [ -e "$custom" ]; then
                cat "$custom" > "$iniTarget"
                iniFound="${custom}"
            fi
        done
        echo -e "${YELLOW}*** ${iniTarget} overwritten with ${iniFound} ***${NC}"
    done
}

setup_phpfarm
setup_php

# Add PHPFarm to PATH
if ! grep -q "phpfarm" /etc/environment ; then
    echo "PATH="$PATH:/opt/phpfarm/inst/bin:/opt/phpfarm/inst/current/bin:/opt/phpfarm/inst/current/sbin"" >> /etc/environment
fi

# Fix ownership
chown -R vagrant:vagrant /opt/phpfarm

# Set Default php to newest available
/opt/phpfarm/inst/bin/switch-phpfarm $(ls -1 /opt/phpfarm/inst/ | grep php | tail -n1 | cut -d'-' -f2);
