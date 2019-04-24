# PHP functions:
function phpRestart() {
    source /vagrant/files/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpName=${arr[1]}
        sudo service php-${phpName} restart
    done;
}

function xdebug {
    state=$([ ${1:-1} == 0 ] && echo ";");
    echo $([ ${1:-1} == 0 ] && echo "Disabling" || echo "Enabling")" X-Debug:"
    services=$(ls -a /etc/init.d/ | grep php);
    ini_files=$(ls -df /opt/phpfarm/inst/php-*/etc/php.ini);
    for ini in ${ini_files}
        do sudo sed -i "s/[;]*zend_extension=xdebug.so/${state}zend_extension=xdebug.so/g" ${ini};
    done;
    for svc in ${services}
        do echo -n "  * Restarting ${svc}... " && sudo service ${svc} restart > null && echo "done."
    done;
}

function makePhpShortformAliases {
    source /vagrant/files/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpAlias="php${arr[1]}='/opt/phpfarm/inst/php-${arr[0]}/bin/php'"
        alias $phpAlias;
    done;
}

makePhpShortformAliases

