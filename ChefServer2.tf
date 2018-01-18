#create a public IP address for the virtual machine
resource "azurerm_public_ip" "chef2_pubip" {
  name                         = "chef2_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "jm-tr-chef2"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "chef2_ip" {
  name                = "chef2_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "chef2_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.chef2_pubip.id}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "chef2" {
  name                  = "chef2"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.chef2_ip.id}"]
  vm_size               = "${var.chef_vm_size}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "chef2_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jm-tr-chef2"
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
    host     = "${azurerm_public_ip.chef2_pubip.fqdn}"
    type     = "ssh"
    user     = "${var.username}"
    password = "${var.password}"
  }

  provisioner "file" {
    source      = "labadmin"
    destination = "/home/labadmin/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "labadmin.pub"
    destination = "/home/labadmin/.ssh/authorized_keys"
  }

  provisioner "file" {
    source      = "InstallChefServer.sh"
    destination = "/tmp/InstallChefServer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefServer.sh",
      "sudo /tmp/InstallChefServer.sh -a ${var.automate_server_name} -z ${var.azure_region} -c jm-tr-chef2 -v ${var.chef_server_version} -u ${var.chef_server_user} -p ${var.chef_server_user_password} -n ${var.chef_server_user_firstname} -l ${var.chef_server_user_lastname} -e ${var.chef_server_user_email} -s 4th-coffee-dev -f 4th Coffee Co Dev -j ${var.chef_server_install_pushjobs} -h ${var.chef_server_pushjobs_version} -m ${var.chef_server_install_manage} -g ${var.chef_server_manage_version} > install.log ",
    ]
  }
}

# output "cip" {
#   value = "${azurerm_public_ip.chef2_pubip.ip_address}"
# }

output "c2fqdn" {
  value = "${azurerm_public_ip.chef2_pubip.fqdn}"
}