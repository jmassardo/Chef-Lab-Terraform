#!/bin/bash
# Trap arguments
automate_server_name=$1
chef_server_name=$2

apt-get update
apt-get -y install curl unzip
sysctl -w vm.max_map_count=262144
sysctl -w vm.dirty_expire_centisecs=20000

# #setup hostname stuff
sudo hostnamectl set-hostname ${automate_server_name}

# download the Chef Automate 2 package
curl https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate

# install Chef Automate
echo "Installing Chef Automate..."
./chef-automate init-config
./chef-automate deploy config.toml --accept-terms-and-mlsa

# Generate an api token for the chef server
./chef-automate admin-token > admin_token.txt

# Print out logon creds
cat automate-credentials.toml