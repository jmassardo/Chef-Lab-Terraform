#!/bin/bash
# Trap arguments
chef_server_user=$1
chef_server_name=$2
chef_server_org_shortname=$3

# Build chef_repo structure
if [ ! -d ~/chef_repo ]; then
  mkdir ~/chef_repo
fi
if [ ! -d ~/chef_repo/.chef ]; then
  mkdir ~/chef_repo/.chef
fi
if [ ! -d ~/chef_repo/cookbooks ]; then
  mkdir ~/chef_repo/cookbooks
fi
if [ ! -d ~/chef_repo/data_bags ]; then
  mkdir ~/chef_repo/data_bags
fi
if [ ! -d ~/chef_repo/environments ]; then
  mkdir ~/chef_repo/environments
fi
if [ ! -d ~/chef_repo/roles ]; then
  mkdir ~/chef_repo/roles
fi

# Fetch certificate
if [ ! -f ~/chef_repo/.chef/$chef_server_user.pem ]; then
  cp ~/$chef_server_user.pem ~/chef_repo/.chef/$chef_server_user.pem
fi

# Build knife.rb
if [ ! -f ~/chef_repo/.chef/knife.rb ]; then
  echo "# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options" > ~/chef_repo/.chef/knife.rb

  echo "current_dir = File.dirname(__FILE__)" >> ~/chef_repo/.chef/knife.rb
  echo "log_level                :info" >> ~/chef_repo/.chef/knife.rb
  echo "log_location             STDOUT" >> ~/chef_repo/.chef/knife.rb
  echo "node_name                \"${chef_server_user}\"" >> ~/chef_repo/.chef/knife.rb
  echo "client_key               \"#{current_dir}/${chef_server_user}.pem\"" >> ~/chef_repo/.chef/knife.rb
  echo "chef_server_url          \"https://${chef_server_name}/organizations/${chef_server_org_shortname}\"" >> ~/chef_repo/.chef/knife.rb
  echo "cookbook_path            [\"#{current_dir}/../cookbooks\"]" >> ~/chef_repo/.chef/knife.rb
  echo "ssl_verify_mode          :verify_none" >> ~/chef_repo/.chef/knife.rb
fi

# Git clone necessary cookbooks and stuff
cd ~/chef_repo/cookbooks
git clone https://github.com/jmassardo/all_systems.git
git clone https://github.com/jmassardo/cis-baseline.git

# Accept Chef licenses
export CHEF_LICENSE="accept"

# Berks upload cookbooks
cd ~/chef_repo/cookbooks/all_systems
berks install
berks upload --ssl-verify=false

cd ~/chef_repo/cookbooks/cis-baseline
berks install
berks upload --ssl-verify=false

# Git clone environments
cd ~/chef_repo/environments
git clone https://github.com/jmassardo/Chef-Jenkins-GlobalEnvironments.git

# Upload environments
knife environment from file ~/chef_repo/environments/Chef-Jenkins-GlobalEnvironments/dev.json
knife environment from file ~/chef_repo/environments/Chef-Jenkins-GlobalEnvironments/prod.json