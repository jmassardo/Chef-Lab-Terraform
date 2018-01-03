#create a public IP address for the virtual machine
resource "azurerm_public_ip" "automate_pubip" {
  name                         = "automate_pubip"
  location                     = "Central US"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "automatesrv"

  tags {
    environment = "staging"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "automate_ip" {
  name                = "automate_ip"
  location            = "Central US"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "automate_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.automate_pubip.id}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "automate" {
  name                  = "automate"
  location              = "Central US"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.automate_ip.id}"]
  vm_size               = "Standard_D4S_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "automate_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "automatesrv"
    admin_username = "automateadmin"
    admin_password = "P@ssword1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"

  }

  connection {
    host     = "${azurerm_public_ip.automate_pubip.fqdn}"
    type     = "ssh"
    user     = "automateadmin"
    password = "P@ssword1234!"
  }

  provisioner "file" {
    source      = "InstallChefAutomate.sh"
    destination = "/tmp/InstallChefAutomate.sh"
  }

  provisioner "file" {
    source      = "delivery.license"
    destination = "/tmp/delivery.license"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefAutomate.sh",
      "sudo /tmp/InstallChefAutomate.sh",
    ]
  }
}

output "aip" {
  value = "${azurerm_public_ip.automate_pubip.ip_address}"
}

output "afqdn" {
  value = "${azurerm_public_ip.automate_pubip.fqdn}"
}