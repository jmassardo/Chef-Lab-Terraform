#!/bin/bash

automate_server_name=$1
chef_server_name=$2
chef_server_version=$3
chef_server_user=$4
chef_server_user_password=$5
chef_server_user_firstname=$6
chef_server_user_lastname=$7
chef_server_user_email=$8
chef_server_org_shortname=$9
chef_server_org_fullname=${10}
chef_server_install_pushjobs=${11}
chef_server_pushjobs_version=${12}
chef_server_install_manage=${13}
chef_server_manage_version=${14}
chefdk_version=${15}

# make sure we have everything we need
apt-get update
apt-get -y install curl

sudo hostnamectl set-hostname ${chef_server_name}

# create staging directories
if [ ! -d /drop ]; then
  mkdir /drop
fi
if [ ! -d /downloads ]; then
  mkdir /downloads
fi

# download the Chef server package

if [ ! -f /downloads/chef-server-core_${chef_server_version}-1_amd64.deb ]; then
  echo "Downloading the Chef server package..."
  wget -nv -P /downloads https://packages.chef.io/files/stable/chef-server/${chef_server_version}/ubuntu/16.04/chef-server-core_${chef_server_version}-1_amd64.deb
fi

# install Chef server
if [ ! $(which chef-server-ctl) ]; then
  echo "Installing Chef server..."
  dpkg -i /downloads/chef-server-core_${chef_server_version}-1_amd64.deb
  chef-server-ctl reconfigure

  echo "Waiting for services..."
  until (curl -D - http://localhost:8000/_status) | grep "200 OK"; do sleep 15s; done
  while (curl http://localhost:8000/_status) | grep "fail"; do sleep 15s; done
fi

# create user and organization
if [ ! $(sudo chef-server-ctl user-list | grep $chef_server_user) ]; then
  echo "Creating $chef_server_user user and $chef_server_org_shortname organization..."
  chef-server-ctl user-create $chef_server_user $chef_server_user_firstname $chef_server_user_lastname $chef_server_user_email $chef_server_user_password --filename ${chef_server_user}.pem
  chef-server-ctl org-create $chef_server_org_shortname "$chef_server_org_fullname" --association_user $chef_server_user --filename ${chef_server_org_shortname}-validator.pem
fi

# fetch token
echo "Fetching the admin token from the A2 server"
scp -o StrictHostKeyChecking=no -i /home/labadmin/.ssh/id_rsa ${chef_server_user}@${automate_server_name}:/home/${chef_server_user}/admin_token.txt .
ADMIN_TOKEN=$(cat admin_token.txt)

# configure data collection
echo "Configuring the data collector"
chef-server-ctl set-secret data_collector token "${ADMIN_TOKEN}"
chef-server-ctl restart nginx
echo "data_collector['root_url'] = 'https://${automate_server_name}/data-collector/v0/'" >> /etc/opscode/chef-server.rb
echo "profiles['root_url'] = 'https://${automate_server_name}'" >> /etc/opscode/chef-server.rb
chef-server-ctl reconfigure

# configure Manage if enabled
if [ "$chef_server_install_manage" = "true" ]; then
  if [ ! $(which chef-manage-ctl) ]; then
    echo "Installing Chef Manage..."
    wget -nv -P /downloads https://packages.chef.io/files/stable/chef-manage/${chef_server_manage_version}/ubuntu/16.04/chef-manage_${chef_server_manage_version}-1_amd64.deb
    chef-server-ctl install chef-manage --path /downloads/chef-manage_${chef_server_manage_version}-1_amd64.deb
    chef-server-ctl reconfigure
    chef-manage-ctl reconfigure --accept-license
  fi
fi

# configure push jobs if enabled
if [ "$chef_server_install_pushjobs" = "true" ]; then
  if [ ! $(which opscode-push-jobs-server-ctl) ]; then
    echo "Installing push jobs server..."
    wget -nv -P /downloads https://packages.chef.io/files/stable/opscode-push-jobs-server/${chef_server_pushjobs_version}/ubuntu/16.04/opscode-push-jobs-server_${chef_server_pushjobs_version}-1_amd64.deb
    chef-server-ctl install opscode-push-jobs-server --path /downloads/opscode-push-jobs-server_${chef_server_pushjobs_version}-1_amd64.deb
    opscode-push-jobs-server-ctl reconfigure
    chef-server-ctl reconfigure
  fi
fi

echo "Installing ChefDK"
wget -nv -P /downloads https://packages.chef.io/files/stable/chefdk/${chefdk_version}/ubuntu/16.04/chefdk_${chefdk_version}-1_amd64.deb
if [ ! $(which chef) ]; then
  echo "Installing ChefDK..."
  dpkg -i /downloads/chefdk_${chefdk_version}-1_amd64.deb
fi

echo "Your Chef server is ready!"