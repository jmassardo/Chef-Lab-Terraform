chef_server_user=$1
chef_server_user_password=$2

cd /var/lib/jenkins/chef_repo
knife bootstrap 10.1.1.20 --ssh-user $chef_server_user --sudo --identity-file ~/.ssh/id_rsa --node-name linuxnode0 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E dev
knife bootstrap 10.1.1.21 --ssh-user $chef_server_user --sudo --identity-file ~/.ssh/id_rsa --node-name linuxnode1 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E dev
knife bootstrap 10.1.1.22 --ssh-user $chef_server_user --sudo --identity-file ~/.ssh/id_rsa --node-name linuxnode2 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E prod
knife bootstrap 10.1.1.23 --ssh-user $chef_server_user --sudo --identity-file ~/.ssh/id_rsa --node-name linuxnode3 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E prod
knife bootstrap 10.1.1.24 --ssh-user $chef_server_user --sudo --identity-file ~/.ssh/id_rsa --node-name linuxnode4 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E prod


knife bootstrap windows winrm 10.1.1.120 --winrm-user $chef_server_user --winrm-password "$chef_server_user_password" --node-name winnode0 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E dev
knife bootstrap windows winrm 10.1.1.121 --winrm-user $chef_server_user --winrm-password "$chef_server_user_password" --node-name winnode1 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E dev
knife bootstrap windows winrm 10.1.1.122 --winrm-user $chef_server_user --winrm-password "$chef_server_user_password" --node-name winnode2 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E prod
knife bootstrap windows winrm 10.1.1.123 --winrm-user $chef_server_user --winrm-password "$chef_server_user_password" --node-name winnode3 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E prod
knife bootstrap windows winrm 10.1.1.124 --winrm-user $chef_server_user --winrm-password "$chef_server_user_password" --node-name winnode4 --run-list 'recipe[all_systems]' --node-ssl-verify-mode none -E prod
