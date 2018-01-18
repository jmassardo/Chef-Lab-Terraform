#create a public IP address for the virtual machine
resource "azurerm_public_ip" "chef_pubip" {
  name                         = "chef_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${var.chef_server_name}"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "chef_ip" {
  name                = "chef_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "chef_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.chef_pubip.id}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "chef" {
  name                  = "chef"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.chef_ip.id}"]
  vm_size               = "${var.chef_vm_size}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "chef_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.chef_server_name}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${var.azure_env}"
  }

  connection {
    host     = "${azurerm_public_ip.chef_pubip.fqdn}"
    type     = "ssh"
    user     = "${var.username}"
    password = "${var.password}"
  }

  provisioner "file" {
    source      = "InstallChefServer.sh"
    destination = "/tmp/InstallChefServer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefServer.sh",
      "sudo /tmp/InstallChefServer.sh -a ${var.automate_server_name} -c ${var.chef_server_name} -v ${var.chef_server_version} -u ${var.chef_server_user} -p ${var.chef_server_user_password} -n ${var.chef_server_user_fullname} -e ${var.chef_server_user_email} -s ${var.chef_server_org_shortname} -f ${var.chef_server_org_fullname} -j ${var.chef_server_install_pushjobs} -jv ${var.chef_server_pushjobs_version} -m ${var.chef_server_install_manage} -mv ${var.chef_server_manage_version} -pv ${var.chef_server_pushjobs_version} ",
    ]
  }
}

# output "cip" {
#   value = "${azurerm_public_ip.chef_pubip.ip_address}"
# }

output "cfqdn" {
  value = "${azurerm_public_ip.chef_pubip.fqdn}"
}