#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup MySql"

# If mysql is already here, move existing data to /srv/mysql/data and change my.cnf to point there
if [ -f /etc/init.d/mysql* ] && [ $(apt-cache policy percona-server-server-5. | grep -c "Installed: 5.") -eq 1 ]; then
    service mysql stop

    sed -i "s/datadir.*/datadir = \/srv\/mysql\/data/" /etc/mysql/my.cnf
    if [ ! -d /srv/mysql/data/mysql ]; then
        echo "Copying mysql databases from /var/lib/mysql/ to /srv/mysql/data ..."
        cp -r /var/lib/mysql/* /srv/mysql/data
    else
        echo "Not moving mysql databases from /var/lib/mysql/ to /srv/mysql/data since data is already present there"
    fi

    # Make sure mysql belongs to the vagrant group for read/write permissions on mound
    usermod -a -G vagrant mysql

    service mysql start

    # Get password for debian-sys-maintainer in case we have existing databases which need to have this set to a new value
    debian_sys_maint_pwd=`sudo grep password /etc/mysql/debian.cnf | head -n1 | cut -d' ' -f3`
    export MYSQL_PWD='root'
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';" | mysql -u'root'
    echo "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${debian_sys_maint_pwd}';" | mysql -u'root'
    export MYSQL_PWD=''
fi

if [ ! -f /etc/init.d/mysql* ] || [ $(apt-cache policy percona-server-server-5. | grep -c "Installed: 5.") -eq 0 ]; then
    wget --progress=bar:force https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
    dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
    DEBIAN_FRONTEND=noninteractive apt-get update
    echo "percona-server-server-5.7 percona-server-server/root_password password root"       | debconf-set-selections
    echo "percona-server-server-5.7 percona-server-server/root_password_again password root" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive apt-get install -y percona-server-server-5.7 percona-server-client-5.7 libmysqlclient-dev 2>&1
    service mysql stop

    printf "[mysqld]\nbind-address = 0.0.0.0\nmax_allowed_packet = 64M\ndatadir = /srv/mysql/data\ninnodb_log_file_size = 256M\ninnodb_use_native_aio=0\n" >> /etc/mysql/my.cnf

    if [ ! -d /srv/mysql/data/mysql ]; then
        echo "Copying mysql databases from /var/lib/mysql/ to /srv/mysql/data ..."
        cp -r /var/lib/mysql/* /srv/mysql/data
    else
        echo "Not moving mysql databases from /var/lib/mysql/ to /srv/mysql/data since data is already present there"
    fi

    # Make sure mysql belongs to the vagrant group for read/write permissions on mound
    usermod -a -G vagrant mysql

    service mysql start

    export MYSQL_PWD='root'
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';" | mysql -u'root'
    export MYSQL_PWD=''
fi

# Upgrade Mysql from 5.6 to 5.7
if [ $(apt-cache policy percona-server-server-5.6 | grep -c "Installed: 5.6") -eq 1 ]; then
    echo "percona-server-server-5.7 percona-server-server/root_password password root"       | debconf-set-selections
    echo "percona-server-server-5.7 percona-server-server/root_password_again password root" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive apt-get install -y percona-server-server-5.7 percona-server-client-5.7 libmysqlclient-dev 2>&1
    export MYSQL_PWD='root'
    mysql_upgrade -u'root'
    export MYSQL_PWD=''
    service mysql restart
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y percona-toolkit 2>&1

# Setup mysql-sync script
yes | cp -rf /vagrant/files/tools/mysql-sync.sh /usr/local/bin/mysql-sync
chmod +x /usr/local/bin/mysql-sync
