#!/bin/bash

# Trap arguments
while getopts a:c:d:e:v:u:p:z: option
do
 case "${option}"
 in
 a) automate_server_name=${OPTARG};;
 c) chef_server_name=${OPTARG};;
 d) chef_server_user=${OPTARG};;
 e) chef_server_org_shortname=${OPTARG};;
 v) automate_server_version=${OPTARG};;
 u) automate_server_user=${OPTARG};;
 p) automate_server_user_password=${OPTARG};;
 z) azure_region=${OPTARG};;

 esac
done

apt-get update
apt-get -y install curl

#chef_server_fqdn=jrm-tr-chefsrv.centralus.cloudapp.azure.com

#setup hostname stuff
#echo "$(hostname -i)  automatesrv.cheflab.local" | tee -a /etc/hosts
sudo hostnamectl set-hostname ${automate_server_name}.${azure_region}.cloudapp.azure.com

# Configure Automate pre-reqs
sudo sysctl -w vm.swappiness=1
sudo sysctl -w vm.max_map_count=256000
sudo sysctl -w vm.dirty_expire_centisecs=30000
sudo sysctl -w net.ipv4.ip_local_port_range='35000 65000'
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
sudo blockdev --setra 4096 /dev/sda1

# create downloads directory
if [ ! -d /downloads ]; then
  mkdir /downloads
fi

# download the Chef Automate package
if [ ! -f /downloads/automate_${automate_server_version}-1_amd64.deb ]; then
  echo "Downloading the Chef Automate package..."
  wget -nv -P /downloads https://packages.chef.io/files/stable/automate/${automate_server_version}/ubuntu/16.04/automate_${automate_server_version}-1_amd64.deb
fi

# install Chef Automate
if [ ! $(which automate-ctl) ]; then
  echo "Installing Chef Automate..."
  dpkg -i /downloads/automate_${automate_server_version}-1_amd64.deb

  # run preflight check
  automate-ctl preflight-check

  # wait until uer pem file has been scp'ed from chef server
  while [ ! -f /tmp/${chef_server_user}.pem ]
do
  echo "Waiting for the chef user pem..."
  sleep 30
done

  # run setup
  automate-ctl setup --license /tmp/delivery.license --key /tmp/${chef_server_user}.pem --server-url https://${chef_server_name}.${azure_region}.cloudapp.azure.com/organizations/${chef_server_org_shortname} --fqdn $(hostname) --enterprise ${chef_server_org_shortname} --configure --no-build-node
  automate-ctl reconfigure

  # wait for all services to come online
  echo "Waiting for services..."
  until (curl --insecure -D - https://localhost/api/_status) | grep "200 OK"; do sleep 1m && automate-ctl restart; done
  while (curl --insecure https://localhost/api/_status) | grep "fail"; do sleep 15s; done

  # create an initial user
  echo "Creating delivery user..."
  automate-ctl create-user $chef_server_org_shortname $automate_server_user --password $automate_server_user_password --roles "admin"
fi

echo "Your Chef Automate server is ready!"