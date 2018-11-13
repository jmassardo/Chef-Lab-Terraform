#create a public IP address for the virtual machine
resource "azurerm_public_ip" "linuxnode_pubip" {
  count                        = "${var.chef_node_count}"
  name                         = "linuxnode${count.index}_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "linuxnode${count.index}-${lower(substr("${join("", split(":", timestamp()))}", 8, -1))}"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "linuxnode_ip" {
  count               = "${var.chef_node_count}"
  name                = "linuxnode${count.index}_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "linuxnode${count.index}_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost("10.1.1.20/24", 20+count.index)}"
    public_ip_address_id          = "${element(azurerm_public_ip.linuxnode_pubip.*.id, count.index + 1)}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "linuxnode" {
  count                 = "${var.chef_node_count}"
  name                  = "linuxnode${count.index}"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.linuxnode_ip.*.id, count.index)}"]
  vm_size               = "${var.chef_node_vm_size}"
  depends_on            = ["azurerm_virtual_machine.chef"]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "linuxnode${count.index}_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "linuxnode${count.index}"
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
    host     = "${element(azurerm_public_ip.linuxnode_pubip.*.fqdn, count.index + 1)}"
    type     = "ssh"
    user     = "${var.username}"
    password = "${var.password}"
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
}
