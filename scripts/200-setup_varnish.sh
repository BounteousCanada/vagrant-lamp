#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup Varnish"

# Setup Varnish
apt-get install -y varnish 2>&1
sed -i.bak 's/.port = "8080";$/.port = "8090";\n    .connect_timeout = 30s;\n    .first_byte_timeout = 3000s;\n    .between_bytes_timeout = 50s;/' /etc/varnish/default.vcl

if [ ! -f /etc/default/varnish.bak ]; then
    cp /etc/default/{varnish,varnish.bak}
    cat > /etc/default/varnish <<EOF
START=yes
NFILES=131072
MEMLOCK=82000
DAEMON_OPTS="-a :80 \\
             -T localhost:6082 \\
             -f /etc/varnish/default.vcl \\
             -S /etc/varnish/secret \\
             -s malloc,256m"
EOF
fi

if [ -f /lib/systemd/system/varnish.service ] && [ $(grep -c "a :6081" /lib/systemd/system/varnish.service) -eq 1 ] ; then
    sed -i "s/a :6081/a :80/" /lib/systemd/system/varnish.service
    systemctl daemon-reload
    systemctl restart varnish.service
fi
