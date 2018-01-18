#create a public IP address for the virtual machine
resource "azurerm_public_ip" "node_pubip" {
  count = "${var.chef_node_count}"
  name                         = "node${count.index}_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "jm-tr-node${count.index}"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "node_ip" {
  count = "${var.chef_node_count}"
  name                = "node${count.index}_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "node${count.index}_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    # public_ip_address_id          = ["${element(azurerm_public_ip.node_pubip.*.id, count.index)}"]
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "node" {
  count = "${var.chef_node_count}"
  name                  = "node${count.index}"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.node_ip.*.id, count.index)}"]
  vm_size               = "${var.chef_node_vm_size}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "node${count.index}_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jm-tr-node${count.index}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${var.azure_env}"
  }

  # connection {
                
  #   host     = ["${element(azurerm_public_ip.node.*._pubip.fqdn, count.index)}"]
  #   type     = "ssh"
  #   user     = "${var.username}"
  #   password = "${var.password}"
  # }

  # provisioner "file" {
  #   source      = "labadmin"
  #   destination = "/home/labadmin/.ssh/id_rsa"
  # }

  # provisioner "file" {
  #   source      = "labadmin.pub"
  #   destination = "/home/labadmin/.ssh/authorized_keys"
  # }

}

# output "node${count.index}fqdn" {
#   value = ["${element(azurerm_public_ip.node.*._pubip.fqdn, count.index)}"]
# }