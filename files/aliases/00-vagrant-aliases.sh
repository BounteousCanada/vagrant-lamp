# Useful Aliases
alias lh='ls -alh'
alias sudo='sudo '
alias mem='free | awk '\''/Mem/{printf("Memory used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%\n"), 100-($4/($3+$4)*100)}'\'''
alias www='cd /srv/www'


# Vagrant helper functions and aliases:
function vhelp {
    versions=''
    vhost_sites="$(vhost sites | sed 's/$/\\n/g' | tr -d '\n')"
    source /vagrant/files/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpVersion=${arr[0]}
        phpName=${arr[1]}
        phpv_x=${phpVersion}'     '
        phpn_x=${phpName}'     '
        line="    * PHP ${phpv_x:0:6}      - alias php${phpn}"
        versions="${versions}${line}\n"
    done;

    text=$(sed "s|###php_versions###|${versions}|g" /vagrant/files/welcome.txt | sed "s|###vhost_sites###|${vhost_sites}|g");
    echo -e "$text"
}

function vstatus {
    echo -e "\n\033[1;32mvstatus - Vagrant Status\033[0;32m"
    echo -e "  Disk Used:      `df -h --output='pcent' / | tail -n1` (Vagrant) `df -h --output='pcent' /vagrant | tail -n1` (Host)"
    echo -e "  `free | awk '/Mem/{printf(\"Memory used:     %.0f% (RAM)\"), $3/$2*100} /buffers\/cache/{printf(\"      %.0f% (Buffers)\"), 100-($4/($3+$4)*100)}'`\n"
    echo -e "  Apache2 Status:          $(if [[ $(sudo service apache2      status | grep 'not running') == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "  Varnish Status:          $(if [[ $(sudo pgrep varnishd) != '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "  Mysql Status:            $(if [[ $(sudo service mysql        status | grep 'is stopped')  == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "  Redis Status:            $(if [[ $(sudo service redis-server status | grep 'not running') == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "  Elasticsearch Status:    $(if [[ $(sudo service redis-server status | grep 'failed') == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "\033[0m"
}

