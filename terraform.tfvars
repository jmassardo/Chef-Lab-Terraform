# Azure Options
azure_region = "centralus" # Use region shortname here as it's interpolated into the URLs
azure_env = "Dev"
azure_rg_name = "jm-tr-lab"

# Shared Options
username = "labadmin"
password = "P@ssw0rd1234!"
chef_node_count = "5"
chef_node_vm_size = "Standard_DS1_v2"

# Automate Options
automate_server_name = "jm-tr-automate"
automate_vm_size = "Standard_D4S_v3"
automate_server_version = "1.7.114"
automate_server_user = "delivery"
automate_server_user_password = "P@ssw0rd1234!"

# Chef Server Options
chef_server_name = "jm-tr-chef"
chef_vm_size = "Standard_D2S_v3"
chef_server_version = "12.17.5"
chef_server_user = "delivery"
chef_server_user_firstname = "Chef"
chef_server_user_lastname = "User"
chef_server_user_email = "user@domain.tld"
chef_server_user_password = "P@ssw0rd1234!"
chef_server_org_shortname = "4th-coffee"
chef_server_org_fullname = "4th Coffee Company"
chef_server_install_pushjobs = "false"
chef_server_pushjobs_version = "2.2.6"
chef_server_install_manage = "true"
chef_server_manage_version = "2.5.8"