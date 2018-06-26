#create a public IP address for the virtual machine
resource "azurerm_public_ip" "automate2_pubip" {
  name                         = "automate2_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${var.automate2_server_name}"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "automate2_ip" {
  name                = "automate2_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "automate2_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.1.1.12"
    public_ip_address_id          = "${azurerm_public_ip.automate2_pubip.id}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "automate2" {
  name                  = "automate2"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.automate2_ip.id}"]
  vm_size               = "${var.automate_vm_size}"
  depends_on            = ["azurerm_virtual_machine.automate"]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "automate2_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.automate2_server_name}"
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
    host     = "${azurerm_public_ip.automate2_pubip.fqdn}"
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
    source      = "InstallChefAutomate2.sh"
    destination = "/tmp/InstallChefAutomate2.sh"
  }

  provisioner "file" {
    source      = "config.toml"
    destination = "/tmp/config.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefAutomate2.sh",
      "sudo /tmp/InstallChefAutomate2.sh ${var.automate_server_name} ${var.chef_server_name} ${var.automate2_server_name}",
    ]
  }
}

# output "aip" {
#   value = "${azurerm_public_ip.automate_pubip.ip_address}"
# }

output "a2fqdn" {
  value = "${azurerm_public_ip.automate2_pubip.fqdn}"
}
