#!/bin/bash
apt-get update
apt-get -y install curl

chef_server_fqdn=chefsrv.centralus.cloudapp.azure.com

#setup hostname stuff
#echo "$(hostname -i)  automatesrv.cheflab.local" | tee -a /etc/hosts
sudo hostnamectl set-hostname automatesrv.centralus.cloudapp.azure.com

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
if [ ! -f /downloads/automate_1.7.39-1_amd64.deb ]; then
  echo "Downloading the Chef Automate package..."
  wget -nv -P /downloads https://packages.chef.io/files/stable/automate/1.7.39/ubuntu/16.04/automate_1.7.39-1_amd64.deb
fi

# install Chef Automate
if [ ! $(which automate-ctl) ]; then
  echo "Installing Chef Automate..."
  dpkg -i /downloads/automate_1.7.39-1_amd64.deb

  # run preflight check
  automate-ctl preflight-check

  # run setup
  automate-ctl setup --license /tmp/delivery.license --key /tmp/delivery.pem --server-url https://$chef_server_fqdn/organizations/4thcoffee --fqdn $(hostname) --enterprise default --configure --no-build-node
  automate-ctl reconfigure

  # wait for all services to come online
  echo "Waiting for services..."
  until (curl --insecure -D - https://localhost/api/_status) | grep "200 OK"; do sleep 1m && automate-ctl restart; done
  while (curl --insecure https://localhost/api/_status) | grep "fail"; do sleep 15s; done

  # create an initial user
  echo "Creating delivery user..."
  automate-ctl create-user default delivery --password P@ssw0rd1234! --roles "admin"
fi

echo "Your Chef Automate server is ready!"