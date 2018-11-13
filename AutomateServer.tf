#create a public IP address for the virtual machine
resource "azurerm_public_ip" "automate_pubip" {
  name                         = "automate_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${var.automate_server_name}-${lower(substr("${join("", split(":", timestamp()))}", 8, -1))}"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "automate_ip" {
  name                = "automate_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "automate_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.1.1.11"
    public_ip_address_id          = "${azurerm_public_ip.automate_pubip.id}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "automate" {
  name                  = "automate"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.automate_ip.id}"]
  vm_size               = "${var.automate_vm_size}"

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
    computer_name  = "${var.automate_server_name}"
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
    host     = "${azurerm_public_ip.automate_pubip.fqdn}"
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

  provisioner "file" {
    source      = "InstallChefAutomate.sh"
    destination = "/tmp/InstallChefAutomate.sh"
  }

  provisioner "file" {
    source      = "profiles/admin-linux-baseline-2.2.2.tar.gz"
    destination = "/tmp/admin-linux-baseline-2.2.2.tar.gz"
  }


  provisioner "file" {
    source      = "profiles/admin-linux-patch-baseline-0.4.0.tar.gz"
    destination = "/tmp/admin-linux-patch-baseline-0.4.0.tar.gz"
  }


  provisioner "file" {
    source      = "profiles/admin-windows-baseline-1.1.0.tar.gz"
    destination = "/tmp/admin-windows-baseline-1.1.0.tar.gz"
  }


  provisioner "file" {
    source      = "profiles/admin-windows-patch-baseline-0.4.0.tar.gz"
    destination = "/tmp/admin-windows-patch-baseline-0.4.0.tar.gz"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstallChefAutomate.sh",
      "sudo /tmp/InstallChefAutomate.sh ${azurerm_public_ip.automate_pubip.fqdn} ${azurerm_public_ip.chef_pubip.fqdn} ${var.username} ${var.password} ${var.chefdk_version}",
    ]
  }
}

output "afqdn" {
  value = "${azurerm_public_ip.automate_pubip.fqdn}"
}
