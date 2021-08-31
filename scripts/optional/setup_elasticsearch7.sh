#!/usr/bin/env bash
# Enable trace printing and exit on the first error
set -e

# Include helper functions
source /vagrant/files/setup_helper.sh

# Print Header
print_header "Setup ElasticSearch"

# Install the required Java
apt-get install -y openjdk-8-jre-headless 2>&1

# Install ElasticSearch

if [ ! -f /etc/elasticsearch/elasticsearch.yml ] || apt-cache policy elasticsearch | grep -q "Installed: 6."; then
    cd /tmp

    if apt-cache policy elasticsearch | grep -q "Installed: 6."; then
      apt-get remove -y elasticsearch
      rm /etc/elasticsearch/elasticsearch.yml
      rm /etc/apt/sources.list.d/elastic-6.x.list
    fi

    wget --progress=bar:force https://artifacts.elastic.co/GPG-KEY-elasticsearch
    apt-key add GPG-KEY-elasticsearch
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list

    apt-get update
    yes | apt-get -y install elasticsearch

    echo "indices.query.bool.max_clause_count: 10024" >> /etc/elasticsearch/elasticsearch.yml

    # Start on boot
    systemctl enable elasticsearch.service
    systemctl restart elasticsearch.service
elif [ $(grep -c "indices.query.bool.max_clause_count" /etc/elasticsearch/elasticsearch.yml ) -eq 0 ] ; then
    echo "indices.query.bool.max_clause_count: 10024" >> /etc/elasticsearch/elasticsearch.yml
    service elasticsearch restart
fi
