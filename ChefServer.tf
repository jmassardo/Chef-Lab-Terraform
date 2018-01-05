#create a public IP address for the virtual machine
resource "azurerm_public_ip" "Chef_pubip" {
  name                         = "Chef_pubip"
  location                     = "Central US"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "chefsrv"

  tags {
    environment = "staging"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "Chef_ip" {
  name                = "Chef_ip"
  location            = "Central US"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "Chef_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.Chef_pubip.id}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "Chef" {
  name                  = "Chef"
  location              = "Central US"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.Chef_ip.id}"]
  vm_size               = "Standard_DS3_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "Chef_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "chefsrv"
    admin_username = "chefadmin"
    admin_password = "P@ssword1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"
  }

  connection {
    host     = "${azurerm_public_ip.Chef_pubip.fqdn}"
    type     = "ssh"
    user     = "chefadmin"
    password = "P@ssword1234!"
  }

  provisioner "file" {
    source      = "InstallChefServer.sh"
    destination = "/tmp/InstallChefServer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefServer.sh",
      "sudo /tmp/InstallChefServer.sh",
    ]
  }
}

output "cip" {
  value = "${azurerm_public_ip.Chef_pubip.ip_address}"
}

output "cfqdn" {
  value = "${azurerm_public_ip.Chef_pubip.fqdn}"
}