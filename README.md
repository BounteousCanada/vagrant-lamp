# Bounteous Flavoured vagrant-lamp

Jump to [Goal](#goal) | [Requirements](#requirements) | [Setup](#setup) | [Configuration](#configuration) | [Changelog](#changelog)

### Goal
The goal of this project is to create an easy to use, reliable development environment.
This was built as a MAMP/WAMP replacement, meeting the requirements of Magento 1 & 2
specifically.

### Requirements

- [Vagrant 1.8+](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Setup

    # Install git and BounteousCanada/Vagrant-Lamp
    git clone https://github.com/BounteousCanada/vagrant-lamp.git
    cd vagrant-lamp

    # Copy example.config.yml to config.yml and edit options
    cp example.config.yml config.yml
    vim config.yml

    # Run Vagrant Up to download and setup the VM
    vagrant up

    # Prestissimo speed up installation on active PHP version
    composer global require hirak/prestissimo

### Configuration
-   config.yml settings
    -   vagrant_hostname: Hostname on Guest VM
        -   Recommended leave default `bounteous.vm.dev`
    -   vagrant_machine_name: Vagrant Machine Name, used for creating unique VM
        -   Recommended leave default `bounteous.vm`
    -   vagrant_ip: IP addressed used to access Guest VM from Local machine
        -   Recommended leave default `192.168.33.10`
    -   vagrant_public_ip: Public IP address of VM
        -   Recommended leave default `empty`
    -   vagrant_memory: Memory to assign to VM
        -   Recommended leave default `auto`, assigns 50% of available system ram, recommended `4096` or more for M2 projects
    -   vagrant_cpus: CPU Cores to assign to VM
        -   Recommended leave default `auto`, assigns all physical cores at 75% max utilization
    -   vagrant_disk_size: Disk size to allocate to VM
        -   Defaults to 20GB dynamically allocated, can only be increased in size not decreased
    -   vagrant_synced_folders: Shared Folders from HOST machine to Guest
        -   local_path: Path on Host machine to share
        -   destination: Path on Guest machine to mount share
        -   type: Share Type \[[nfs](https://www.vagrantup.com/docs/synced-folders/nfs.html)|[smb](https://www.vagrantup.com/docs/synced-folders/smb.html)|[rsync](https://www.vagrantup.com/docs/synced-folders/rsync.html)\]
            -   Recommended leave default as empty.  Mac OS users may use nfs but not recommended for the mysql share as nfs bind may run out of connections
        -   create: Create directory on HOST machine if it doesn't exist
            -   Recommended leave default `true`
        ```
        # Example of Multiple Shared Folders
        vagrant_synced_folders:
          - local_path: ~/projects/www
            destination: /srv/www
            type: nfs
            create: true

          - local_path: ~/projects/mysql
            destination: /srv/mysql
            type:
            create: true

          - local_path: ~/projects/backup
            destination: /srv/backup
            type: nfs
            create: true
        ```
    - vagrant_optional_software: Optional software that can be installed (disabled by default)
        ```
        # Example of Optional software to install
        vagrant_optional_software:
          - name: solr
            enabled: true

          - name: rabbitmq
            enabled: false
        ```
    - vagrant_php_versions: Settings to determine which versions of PHP to install/build
        -   enabled: Enabled or Disables this version (disabled versions are removed from phpfarm on provisioning)
        -   alias: Used for the creation of PHP alias's allowing you to call specific PHP versions from anywhere (ie `alias: 7.3` creates an alias in the vm of `php7.3`)
            -   `NOTE: must be unique between versions`
        -   version: PHP version to install (at the moment 5.5.38, 5.6.40, 7.0.33, 7.1.27, 7.2.16 and 7.3.4 are available pre-compiled, any other version will attempt to build during provisioning )
        -   port: PHP port to use
            -   `NOTE: must be unique between versions`
        -   build: When included and set to `true` the pre-compiled version will not be downloaded but instead will be built during provisioning (OPTIONAL)
        ```
        # Example of PHP versions to install
        vagrant_php_versions:
          - enabled: false
            alias: 5.5
            version: 5.5.38
            port: 9055

          - enabled: false
            alias: 5.6
            version: 5.6.40
            port: 9056

          - enabled: false
            alias: 7
            version: 7.0.33
            port: 9070

          - enabled: true
            alias: 7.1
            version: 7.1.27
            port: 9071
            build: true

          - enabled: true
            alias: 7.2
            version: 7.2.16
            port: 9072

          - enabled: false
            alias: 7.3
            version: 7.3.4
            port: 9073
        ```


#### The following are available:

-   Apache2 2.4.29
-   Percona 5.6 (MySQL Server and Client)
-   Varnish 5.2.1
-   Redis
-   PHP-FPM 5.5, 5.6, 7.0, 7.1, 7.2 & 7.3 /w Xdebug (via PHPFARM)
-   ElasticSearch 6.7.1
-   RabbitMq 3.6.10 (Optional)
-   Solr 3.4.0, 3.5.0 & 3.6.2 (Optional)
-   HTOP
-   dos2unix (on Windows host machines only)
-   smem
-   strace
-   lynx
-   mailhog


#### The following Extra Tools are available:
-   Composer
-   N98-Magerun and N98-Magerun2
-   modman
-   PHPUnit
-   redis
    - Add / Remove or List Redis instances

        ```Usage: sudo redis add|remove|list -n name [-p port] [-s save]```
-   vhost
    - Add / Remove Apache virtualhost entries

        ```Usage: sudo vhost add|remove|list|sites -d DocumentRoot -n ServerName -p PhpVersion [-a ServerAlias] [-s CertPath] [-c CertName] [-f]```
-   solr
    - Add / Remove Solr core entries

        ```Usage: sudo solr add|remove|list -n name [-v version]```
-   mysql-sync
    - Sync Remote Database to VM Mysql instance

        ```Usage: mysql-sync -i remote-ip -p remote-port -u remote-username -d remote-database```
