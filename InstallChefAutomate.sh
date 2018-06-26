#!/bin/bash

# Trap arguments
automate_server_name=$1
chef_server_name=$2
chef_server_user=$3
chef_server_org_shortname=$4
automate_server_version=$5
automate_server_user=$6
automate_server_user_password=$7
azure_region=$8
user_name=$9
inspec_version=${10}

apt-get update
apt-get -y install curl

echo 10.1.1.10 ${chef_server_name}.lab.local | sudo tee -a /etc/hosts
echo 10.1.1.11 ${automate_server_name}.lab.local | sudo tee -a /etc/hosts
echo 10.1.1.12 automate2.lab.local | sudo tee -a /etc/hosts
sudo hostnamectl set-hostname ${automate_server_name}.lab.local

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

  # Fetch user pem from Chef server
  chmod 700 ~/.ssh/id_rsa 
  ssh-keyscan ${chef_server_name}.lab.local >> ~/.ssh/known_hosts
  sleep 5s
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ri ~/.ssh/id_rsa ${user_name}@${chef_server_name}.lab.local:/drop/${chef_server_user}.pem ${chef_server_user}.pem 

  # run setup
  automate-ctl setup --license /tmp/automate.license --key ~/${chef_server_user}.pem --server-url https://${chef_server_name}.lab.local/organizations/${chef_server_org_shortname} --fqdn $(hostname) --enterprise ${chef_server_org_shortname} --configure --no-build-node
  automate-ctl reconfigure

  # wait for all services to come online
  echo "Waiting for services..."
  until (curl --insecure -D - https://localhost/api/_status) | grep "200 OK"; do sleep 1m && automate-ctl restart; done
  while (curl --insecure https://localhost/api/_status) | grep "fail"; do sleep 15s; done

  # create an initial user
  echo "Creating Automate user..."
  automate-ctl create-user $chef_server_org_shortname $automate_server_user --password $automate_server_user_password --roles "admin"
fi

# Install Inspec
wget -nv -P /downloads https://packages.chef.io/files/stable/inspec/${inspec_version}/ubuntu/16.04/inspec_${inspec_version}-1_amd64.deb
dpkg -i /downloads/inspec_${inspec_version}-1_amd64.deb

# Log into Automate then upload profiles
inspec compliance login https://localhost --insecure --user=${automate_server_user} --ent=${chef_server_org_shortname} --dctoken 93a49a4f2482c64126f7b6015e6b0f30284287ee4054ff8807fb63d9cbd1c506
inspec compliance upload /tmp/labadmin-linux-patch-baseline-0.4.0.tar.gz
inspec compliance upload /tmp/labadmin-cis-ubuntu16.04lts-level1-server-1.0.0-3.tar.gz

# Setup A1-A2 forwarding
cp /tmp/05-a2-forwarder.conf /opt/delivery/embedded/etc/logstash/conf.d/05-a2-forwarder.conf
automate-ctl restart logstash

echo "Your Chef Automate server is ready!"