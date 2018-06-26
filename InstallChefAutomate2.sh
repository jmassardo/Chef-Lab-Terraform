#!/bin/bash
# Trap arguments
automate_server_name=$1
chef_server_name=$2
automate2_server_name=$3

apt-get update
apt-get -y install curl unzip
sysctl -w vm.max_map_count=262144
sysctl -w vm.dirty_expire_centisecs=20000

#setup hostname stuff
echo 10.1.1.10 ${chef_server_name}.lab.local | sudo tee -a /etc/hosts
echo 10.1.1.11 ${automate_server_name}.lab.local | sudo tee -a /etc/hosts
echo 10.1.1.12 ${automate2_server_name}.lab.local | sudo tee -a /etc/hosts
sudo hostnamectl set-hostname ${automate2_server_name}.lab.local

# download the Chef Automate 2 package
curl https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate

# install Chef Automate
echo "Installing Chef Automate..."
~/chef-automate deploy /tmp/config.toml --accept-terms-and-mlsa

# Print out logon creds
cat automate-credentials.toml