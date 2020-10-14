#create a public IP address for the virtual machine
resource "azurerm_public_ip" "chef_pubip" {
  name                = "chef_pubip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${var.chef_server_name}-${lower(substr(join("", split(":", timestamp())), 8, -1))}"
  allocation_method   = "Dynamic"
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "chef_ip" {
  name                = "chef_ip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "chef_ipconf"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.1.1.10"
    public_ip_address_id          = azurerm_public_ip.chef_pubip.id
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "chef" {
  name                  = "chef"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.chef_ip.id]
  vm_size               = var.chef_vm_size

  # depends_on            = [azurerm_virtual_machine.automate]

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
    computer_name  = var.chef_server_name
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    host     = azurerm_public_ip.chef_pubip.fqdn
    type     = "ssh"
    user     = var.username
    password = var.password
  }

  provisioner "file" {
    source      = "labadmin"
    destination = "/home/${var.username}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /home/${var.username}/.ssh/id_rsa",
    ]
  }

  provisioner "file" {
    source      = "labadmin.pub"
    destination = "/home/${var.username}/.ssh/authorized_keys"
  }

  provisioner "file" {
    source      = "InstallChefServer.sh"
    destination = "/tmp/InstallChefServer.sh"
  }

  # provisioner "file" {
  #   source      = "ChefTheThings.sh"
  #   destination = "/tmp/ChefTheThings.sh"
  # }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefServer.sh",
      "sudo /tmp/InstallChefServer.sh 10.1.1.12 ${azurerm_public_ip.chef_pubip.fqdn} ${var.chef_server_version} ${var.username} ${var.password} ${var.chef_server_user_firstname} ${var.chef_server_user_lastname} ${var.chef_server_user_email} ${var.chef_server_org_shortname} '${var.chef_server_org_fullname}' ${var.chef_server_install_pushjobs} ${var.chef_server_pushjobs_version} ${var.chef_server_install_manage} ${var.chef_server_manage_version} ${var.chefdk_version} > install.log ",
    ]
    # ${azurerm_public_ip.automate_pubip.fqdn}
    # "sudo chmod +x /tmp/ChefTheThings.sh",
    # "sudo /tmp/ChefTheThings.sh ${var.username} ${azurerm_public_ip.chef_pubip.fqdn} ${var.chef_server_org_shortname} > chef_the_things.log",
  }
}

output "cfqdn" {
  value = azurerm_public_ip.chef_pubip.fqdn
}

