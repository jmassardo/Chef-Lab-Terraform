#!/bin/bash

automate_server_name=$1
chef_server_name=$2
jenkins_server_name=$3
chefdk_version=$4

# make sure we have everythign we need
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
echo deb https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get -y install curl nginx default-jdk jenkins

echo 10.1.1.10 ${chef_server_name}.lab.local | sudo tee -a /etc/hosts
echo 10.1.1.11 ${automate_server_name}.lab.local | sudo tee -a /etc/hosts
echo 10.1.1.13 ${jenkins_server_name}.lab.local | sudo tee -a /etc/hosts
sudo hostnamectl set-hostname ${jenkins_server_name}.lab.local

# create staging directories
if [ ! -d /drop ]; then
  mkdir /drop
fi
if [ ! -d /downloads ]; then
  mkdir /downloads
fi

echo "Installing ChefDK..."
wget -nv -P /downloads https://packages.chef.io/files/stable/chefdk/${chefdk_version}/ubuntu/16.04/chefdk_${chefdk_version}-1_amd64.deb
dpkg -i /downloads/chefdk_${chefdk_version}-1_amd64.deb

echo "Your Jenkins server is ready!"