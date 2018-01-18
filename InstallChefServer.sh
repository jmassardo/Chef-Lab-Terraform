#!/bin/bash

# Trap arguments
while getopts a:z:c:v:u:p:n:l:e:s:f:j:h:m:g: option
do
 case "${option}"
 in
 a) automate_server_name=${OPTARG};;
 z) azure_region=${OPTARG};;
 c) chef_server_name=${OPTARG};;
 v) chef_server_version=${OPTARG};;
 u) chef_server_user=${OPTARG};;
 p) chef_server_user_password=${OPTARG};;
 n) chef_server_user_firstname=${OPTARG};;
 l) chef_server_user_lastname=${OPTARG};;
 e) chef_server_user_email=${OPTARG};;
 s) chef_server_org_shortname=${OPTARG};;
 f) chef_server_org_fullname=${OPTARG};;
 j) chef_server_install_pushjobs=${OPTARG};;
 h) chef_server_pushjobs_version=${OPTARG};;
 m) chef_server_install_manage=${OPTARG};;
 g) chef_server_manage_version=${OPTARG};;

 esac
done

# make sure we have everythign we need
apt-get update
apt-get -y install curl

#chef_automate_fqdn=jm-tr-automatesrv.centralus.cloudapp.azure.com
#setup hostname stuff
#echo "$(hostname -i)  automatesrv.cheflab.local" | tee -a /etc/hosts
sudo hostnamectl set-hostname ${chef_server_name}.${azure_region}.cloudapp.azure.com

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
  chef-server-ctl user-create $chef_server_user $chef_server_user_firstname $chef_server_user_lastname $chef_server_user_email $chef_server_user_password --filename /drop/${chef_server_user}.pem
  chef-server-ctl org-create $chef_server_org_shortname "$chef_server_org_fullname" --association_user $chef_server_user --filename ${chef_server_org_shortname}-validator.pem
fi

# SCP user pem to automate server
chmod 700 ~/.ssh/id_rsa 
ssh-keyscan  ${automate_server_name}.${azure_region}.cloudapp.azure.com >> ~/.ssh/known_hosts
sleep 5s
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ri ~/.ssh/id_rsa /drop/${chef_server_user}.pem labadmin@${automate_server_name}.${azure_region}.cloudapp.azure.com:/tmp/${chef_server_user}.pem

# configure data collection
chef-server-ctl set-secret data_collector token '93a49a4f2482c64126f7b6015e6b0f30284287ee4054ff8807fb63d9cbd1c506'
chef-server-ctl restart nginx
echo "data_collector['root_url'] = 'https://${automate_server_name}.${azure_region}.cloudapp.azure.com/data-collector/v0/'" >> /etc/opscode/chef-server.rb
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

echo "Your Chef server is ready!"