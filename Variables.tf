# Azure Options
variable "azure_region" {
  default     = "centralus" # Use region shortname here as it's interpolated into the URLs
  description = "The location/region where the resources are created."
}

variable "azure_env" {
  default     = "Dev"
  description = "This is the name of the environment tag, i.e. Dev, Test, etc."
}

variable "azure_rg_name" {
  default     = "lab" # This will get a unique timestamp appended
  description = "Specify the name of the new resource group"
}

variable "source_address_prefix" {
  default     = "*"
  description = "Specify source prefix i.e. 1.2.3.4/24. This restricts the network security group so only your systems can remotely access the resources. Prevents resources from being exposed directly to the Internet."
}

# Shared Options

variable "username" {
  default     = "labadmin"
  description = "Admin username for all VMs"
}

variable "password" {
  default     = "P@ssw0rd1234!"
  description = "Admin password for all VMs"
}

variable "chefdk_version" {
  default     = "4.5.0"
  description = "Specify the version of ChefDK to install"
}

variable "inspec_version" {
  default     = "4.18.0"
  description = "Specify the version of Inspec to install"
}

variable "chef_node_count" {
  default     = "5"
  description = "How many chef nodes should be provisioned"
}

variable "chef_node_vm_size" {
  default     = "Standard_B2s"
  description = "Specify the VM Size"
}

# Automate Server Options
variable "automate_server_name" {
  default     = "automate"
  description = "Specify the hostname for the Automate server"
}

variable "automate_vm_size" {
  default     = "Standard_D4S_v3"
  description = "Specify the VM Size"
}

# Chef Server Options
variable "chef_server_name" {
  default     = "chef"
  description = "Specify the hostname for the Chef server"
}

variable "chef_vm_size" {
  default     = "Standard_D2S_v3"
  description = "Specify the VM Size i.e. Standard_D2S_v3"
}

variable "chef_server_version" {
  default     = "14.0.58"
  description = "Specify the version of Chef Server to install"
}

variable "chef_server_user_firstname" {
  default     = "Chef"
  description = "First name for Chef user"
}

variable "chef_server_user_lastname" {
  default     = "User"
  description = "Last name for Chef user"
}

variable "chef_server_user_email" {
  default     = "user@domain.tld"
  description = "Email address for Chef user"
}

variable "chef_server_org_shortname" {
  default     = "awesome-org"
  description = "Short name for new Chef Org"
}

variable "chef_server_org_fullname" {
  default     = "My Super Awesome Org"
  description = "Full name for new Chef Org"
}

variable "chef_server_install_pushjobs" {
  default     = "false"
  description = "Install Push Jobs? true/false"
}

variable "chef_server_pushjobs_version" {
  default     = "2.2.8"
  description = "Specify the version of Push Jobs to install"
}

variable "chef_server_install_manage" {
  default     = "false"
  description = "Install Chef Manage? true/false"
}

variable "chef_server_manage_version" {
  default     = "3.0.11"
  description = "Specify the version of Manage to install"
}

# Jenkins Server Options
variable "jenkins_server_name" {
  default     = "jenkins"
  description = "Specify the hostname for the Jenkins server"
}

variable "jenkins_vm_size" {
  default     = "Standard_D2S_v3"
  description = "Specify the VM Size i.e. Standard_D2S_v3"
}

