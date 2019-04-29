# -*- mode: ruby -*-
# vi: set ft=ruby :
mounts_required = Array.[]('/srv/www', '/srv/mysql', '/srv/backup')
mem_ratio = 0.5
cpu_exec_cap = 75
config_php = ''

# Use config.yml for basic VM configuration.
require 'yaml'
require File.dirname(__FILE__)+"/files/dependency_manager"
dir = File.dirname(File.expand_path(__FILE__))
unless File.exist?("#{dir}/config.yml")
  raise 'Configuration file not found! Please copy example.config.yml to config.yml and try again.'
end
vconfig = YAML.load_file("#{dir}/config.yml")

# Check required synced folders are set
mounts_required.each do |required_folder|
  found = false
  vconfig['vagrant_synced_folders'].each do |synced_folder|
    if synced_folder['destination'] == required_folder
      found = true
    end
  end
  if found == false
    puts "\n" +
      '**********************' + "\n" +
      '* Bounteous Vagrant Lamp *' + "\n" +
      '**********************' + "\n" +
      'Your config.yml file must contain ' +
      mounts_required.count.to_s +
      ' vagrant_synced_folders entries' + "\n" +
      'mapping to ' + mounts_required.to_s + "\n" +
      "Please see example.config.yml for details on how to set this.\n" +
      "\n"
    exit
  end
end

# Module for determine host Operating System
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

# Check that bindfs is installed on OSX
if OS.mac?
  check_plugins ["vagrant-bindfs"]
end

# Check that vbquest is installed to keep guest additions up to date
check_plugins ["vagrant-vbguest"]
check_plugins ["vagrant-disksize"]

# Determine CPU's to allocate to virtual machine (Default all cores, fallback 2)
if !vconfig['vagrant_cpus'].empty? && vconfig['vagrant_cpus'].downcase != 'auto'
  cpus = vconfig['vagrant_cpus']
elsif OS.mac?
  cpus = `sysctl -n hw.ncpu`.to_i
elsif OS.linux?
  cpus = `nproc`.to_i
elsif OS.windows?
  cpus = `wmic cpu get NumberOfCores`.split("\n")[2].to_i
else
  cpus = 2
end

# Determine memory to allocate to virtual machine (Default 50% available, fallback 4096mb)
if !vconfig['vagrant_memory'].empty? && vconfig['vagrant_memory'].downcase != 'auto'
  mem = vconfig['vagrant_memory']
elsif OS.mac?
  mem = `sysctl -n hw.memsize`.to_i / 1024^2 * mem_ratio
elsif OS.linux?
  mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 * mem_ratio
elsif OS.windows?
  mem = (`wmic OS get TotalVisibleMemorySize`.split("\n")[2].to_i / 1024 * mem_ratio).round
else
  mem = 4096
end

# Determine disk size to allocate to virtual machine (Default 20GB)
disk_size = vconfig['vagrant_disk_size'] || '20GB'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/bionic64"
  config.disksize.size = vconfig['vagrant_disk_size']

  # Networking configuration.
  config.vm.hostname = vconfig['vagrant_hostname']
  if vconfig['vagrant_ip'] == '0.0.0.0' && Vagrant.has_plugin?('vagrant-auto_network')
    config.vm.network :private_network, ip: vconfig['vagrant_ip'], auto_network: true
  else
    config.vm.network :private_network, ip: vconfig['vagrant_ip']
  end

  if !vconfig['vagrant_public_ip'].empty? && vconfig['vagrant_public_ip'] == '0.0.0.0'
    config.vm.network :public_network
  elsif !vconfig['vagrant_public_ip'].empty?
    config.vm.network :public_network, ip: vconfig['vagrant_public_ip']
  end
  
  # Synced folders.
  vconfig['vagrant_synced_folders'].each do |synced_folder|
    options = {
      type: synced_folder['type'],
      rsync__auto: 'true',
      rsync__exclude: synced_folder['excluded_paths'],
      rsync__args: ['--verbose', '--archive', '--delete', '-z', '--chmod=ugo=rwX'],
      id: synced_folder['id'],
      create: synced_folder.include?('create') ? synced_folder['create'] : false,
      mount_options: synced_folder.include?('mount_options') ? synced_folder['mount_options'] : []
    }

    owner = 'vagrant'
    group = 'vagrant'

    if synced_folder['type'] != 'nfs' || Vagrant::Util::Platform.windows?
       options[:owner] = owner
       options[:group] = group
       options[:mount_options] = ["dmode=775,fmode=775"]
    end

    if synced_folder.include?('options_override')
      options = options.merge(synced_folder['options_override'])
    end

    if synced_folder['type'] == 'nfs' && !Vagrant::Util::Platform.windows?
      config.vm.synced_folder synced_folder['local_path'], '/nfs' + synced_folder['destination'], options
      config.bindfs.bind_folder "/nfs" + synced_folder['destination'], synced_folder['destination'], :owner => owner, :group => group, :'create-as-user' => true, :perms => "u=rwx:g=rwx:o=r", :'create-with-perms' => "u=rwx:g=rwx:o=r", :'chown-ignore' => true, :'chgrp-ignore' => true, :'chmod-ignore' => true
    else
      config.vm.synced_folder synced_folder['local_path'], synced_folder['destination'], options
    end
  end

  #puts "Provisioning VM with #{cpus} CPU's (at #{cpu_exec_cap}%) and #{mem/1024} GB RAM."
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true if Vagrant::VERSION =~ /^1.8/
    vb.name = vconfig['vagrant_hostname']
    vb.customize ["modifyvm", :id, "--memory", mem]
    vb.customize ["modifyvm", :id, "--cpus", cpus]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", cpu_exec_cap]
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--ioapic', 'on']
  end

  # Generate config.php from config.yml
  vconfig['vagrant_php_versions'].each do |php_version|
  puts php_version['enabled']
    if php_version['enabled'].to_s == 'true'
        config_php = config_php + "'#{php_version['version']}  #{php_version['alias']}  #{php_version['port']}  #{php_version['build']||'false'}'\n"
    end
  end
  config.vm.provision "shell", name: "Generate config_php.sh", inline: "echo \"#!/usr/bin/env bash \n# GENERATED FILE - DO NOT EDIT\nconfig_php=(\n#{config_php})\" > /vagrant/files/config_php.sh"

  # Correct potential non-unix line endings in scripts on Windows hosts
  if OS.windows?
    config.vm.provision "shell", name: "Correct non-unix line endings", inline: "apt-get update; apt-get install -y dos2unix; find /vagrant/files -type f -exec dos2unix {} \\;"
  end

  # Run default setup scripts in numbered order:
  @files = Dir.glob("#{dir}/scripts/*.sh").sort.each do |setup_script|
    provision_name = setup_script.split('/')[-1].split('-')[1].split('.')[0]
    config.vm.provision provision_name, keep_color: true, type: "shell", path: setup_script
  end

  # Run setup script for optional software
  vconfig['vagrant_optional_software'].each do |optional_software|
    if optional_software['enabled'].to_s == 'true'
        config.vm.provision "setup_#{optional_software['name']}", keep_color: true, type: "shell", path: "#{dir}/scripts/optional/setup_#{optional_software['name']}.sh"
    end
  end

  config.vm.define vconfig['vagrant_machine_name']

  # Make mysql's socket available to php - e.g.
  # echo "<?php \$li = new mysqli('localhost', 'root', 'root', 'mysql'); ?>" | php
  #config.vm.provision "shell", inline: "if [ ! -L /tmp/mysql.sock ]; then ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock; fi", run: "always"

  #config.vm.provision "shell", inline: "service mysql restart", run: "always"

end
