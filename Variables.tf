# Azure Options
variable "azure_region" {
  description = "The location/region where the resources are created."
}

variable "azure_env" {
  description = "This is the name of the environment tag, i.e. Dev, Test, etc."
}

variable "azure_rg_name" {
  description = "Specify the name of the new resource group"
}

# Shared Options
variable "username" {
  description = "Admin username for all VMs"
}

variable "password" {
  description = "Admin password for all VMs"
}

# Automate Server Options
variable "automate_server_name" {
  description = "Specify the hostname for the Automate server"
}

variable "automate_vm_size" {
  description = "Specify the VM Size i.e. Standard_D4S_v3"
}

variable "automate_server_version" {
  description = "Specify the version of Automate to install i.e. 1.7.114"
}

variable "automate_server_user" {
  description = "Initial username for Automate Server i.e. delivery"
}

variable "automate_server_user_password" {
  description = "Password for Automate user"
}

# Chef Server Options
variable "chef_server_name" {
  description = "Specify the hostname for the Chef server"
}

variable "chef_vm_size" {
  description = "Specify the VM Size i.e. Standard_D2S_v3"
}

variable "chef_server_version" {
  description = "Specify the version of Chef Server to install i.e. 12.17.5"
}

variable "chef_server_user" {
  description = "Initial username for Chef Server i.e. delivery"
}

variable "chef_server_user_firstname" {
  description = "First name for Chef user"
}

variable "chef_server_user_lastname" {
  description = "Last name for Chef user"
}

variable "chef_server_user_email" {
  description = "Email address for Chef user"
}

variable "chef_server_user_password" {
  description = "Password for Chef user"
}

variable "chef_server_org_shortname" {
  description = "Short name for new Chef Org i.e. 4th-coffee"
}

variable "chef_server_org_fullname" {
  description = "Full name for new Chef Org i.e. 4TH Coffee Company"
}

variable "chef_server_install_pushjobs" {
  description = "Install Push Jobs? true/false"
}

variable "chef_server_pushjobs_version" {
  description = "Specify the version of Push Jobs to install i.e. 2.2.6"
}

variable "chef_server_install_manage" {
  description = "Install Chef Manage? true/false"
}

variable "chef_server_manage_version" {
  description = "Specify the version of Manage to install i.e. 2.5.8"
}

variable "chef_node_count" {
  description = "How many chef nodes should be provisioned"
}

variable "chef_node_vm_size" {
  description = "Specify the VM Size i.e. Standard_D1S_v3"
}