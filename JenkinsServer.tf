#create a public IP address for the virtual machine
resource "azurerm_public_ip" "jenkins_pubip" {
  name                = "jenkins_pubip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.jenkins_server_name}-${lower(substr(join("", split(":", timestamp())), 8, -1))}"
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "jenkins_ip" {
  name                = "jenkins_ip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name      = "jenkins_ipconf"
    subnet_id = azurerm_subnet.subnet.id

    # private_ip_address_allocation = "dynamic"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.1.1.13"
    public_ip_address_id          = azurerm_public_ip.jenkins_pubip.id
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "jenkins" {
  name                  = "jenkins"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.jenkins_ip.id]
  vm_size               = var.jenkins_vm_size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jenkins_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.jenkins_server_name
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    host     = azurerm_public_ip.jenkins_pubip.fqdn
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
    source      = "jenkins.rc.local"
    destination = "/home/${var.username}/rc.local"
  }

  provisioner "file" {
    source      = "InstalljenkinsServer.sh"
    destination = "/tmp/InstalljenkinsServer.sh"
  }

  provisioner "file" {
    source      = "BootstrapNodes.sh"
    destination = "/tmp/BootstrapNodes.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/InstalljenkinsServer.sh",
      "sudo chmod +x /tmp/BootstrapNodes.sh",
      "sudo /tmp/BootstrapNodes.sh ${var.username}  ${var.password} > bootstrap_nodes.log",
    ]
  }
}

output "jfqdn" {
  value = azurerm_public_ip.jenkins_pubip.fqdn
}

