#!/bin/bash
# Trap arguments
jenkins_server_name=$1
chefdk_version=$2
chef_server_user=$3
chef_server_name=$4
chef_server_org_shortname=$5

# make sure we have everythign we need
echo "Fetch Apt Key for the Jenkins repo"
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
echo deb https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list

echo "Install the pre-reqs"
apt-get update
apt-get -y install curl default-jdk

echo "Install Jenkins"
apt-get -y install jenkins

sudo hostnamectl set-hostname ${jenkins_server_name}

echo "Installing ChefDK..."
wget https://packages.chef.io/files/stable/chefdk/${chefdk_version}/ubuntu/16.04/chefdk_${chefdk_version}-1_amd64.deb
dpkg -i chefdk_${chefdk_version}-1_amd64.deb

echo "Buildingthe chef_repo folders"
# Build chef_repo structure
if [ ! -d /var/lib/jenkins/chef_repo ]; then
  mkdir /var/lib/jenkins/chef_repo
fi
if [ ! -d /var/lib/jenkins/chef_repo/.chef ]; then
  mkdir /var/lib/jenkins/chef_repo/.chef
fi
if [ ! -d /var/lib/jenkins/chef_repo/cookbooks ]; then
  mkdir /var/lib/jenkins/chef_repo/cookbooks
fi
if [ ! -d /var/lib/jenkins/chef_repo/data_bags ]; then
  mkdir /var/lib/jenkins/chef_repo/data_bags
fi
if [ ! -d /var/lib/jenkins/chef_repo/environments ]; then
  mkdir /var/lib/jenkins/chef_repo/environments
fi
if [ ! -d /var/lib/jenkins/chef_repo/roles ]; then
  mkdir /var/lib/jenkins/chef_repo/roles
fi

if [ ! -f /var/lib/jenkins/chef_repo/.chef/$chef_server_user.pem ]; then
  echo "Fetching the admin pem from the chef server"
  scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ${chef_server_user}@${chef_server_name}:~/${chef_server_user}.pem /var/lib/jenkins/chef_repo/.chef/$chef_server_user.pem
fi

echo "Building the knife.rb"
if [ ! -f /var/lib/jenkins/chef_repo/.chef/knife.rb ]; then
  echo "# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options" > /var/lib/jenkins/chef_repo/.chef/knife.rb

  echo "current_dir = File.dirname(__FILE__)" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "log_level                :info" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "log_location             STDOUT" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "node_name                \"${chef_server_user}\"" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "client_key               \"#{current_dir}/${chef_server_user}.pem\"" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "chef_server_url          \"https://${chef_server_name}/organizations/${chef_server_org_shortname}\"" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "cookbook_path            [\"#{current_dir}/../cookbooks\"]" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
  echo "ssl_verify_mode          :verify_none" >> /var/lib/jenkins/chef_repo/.chef/knife.rb
fi

echo "Fixing the permissions for Jenkins"
chown -R jenkins:jenkins /var/lib/jenkins/chef_repo

echo "Setting up iptables rules"
mv -f /home/${chef_server_user}/rc.local /etc/rc.local
chmod +x /etc/rc.local

echo "one time run of iptables since rc.local won't play nice in terraform"
#Requests from outside
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080
#Requests from localhost
iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 80 -j REDIRECT --to-ports 8080

# Done!
echo "Your Jenkins server is ready!"