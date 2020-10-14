#!/bin/bash
# Trap arguments
automate_server_name=$1
chef_server_name=$2
chef_server_user=$3
chef_server_user_password=$4
chefdk_version=$5
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

# Change the admin password
TOK=$(cat admin_token.txt)
curl -k -X PUT -H "api-token: $TOK" -H "Content-Type: application/json" -d "{\"name\":\"Automate Admin\", \"id\": \"${chef_server_user}\", \"password\": \"${chef_server_user_password}\"}" https://localhost/api/v0/auth/users/admin

# Install ChefDK
wget https://packages.chef.io/files/stable/chefdk/${chefdk_version}/ubuntu/16.04/chefdk_${chefdk_version}-1_amd64.deb
if [ ! $(which chef) ]; then
  echo "Installing ChefDK..."
  dpkg -i chefdk_${chefdk_version}-1_amd64.deb
fi

# Accept Chef licenses
export CHEF_LICENSE="accept"

# Upload profiles to Asset Store
inspec compliance login localhost --insecure --user=admin --dctoken=$TOK
inspec compliance upload /tmp/admin-linux-baseline-2.2.2.tar.gz
inspec compliance upload /tmp/admin-linux-patch-baseline-0.4.0.tar.gz
inspec compliance upload /tmp/admin-windows-baseline-1.1.0.tar.gz
inspec compliance upload /tmp/admin-windows-patch-baseline-0.4.0.tar.gz
inspec compliance logout