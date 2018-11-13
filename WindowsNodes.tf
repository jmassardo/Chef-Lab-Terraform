#create a public IP address for the virtual machine
resource "azurerm_public_ip" "winnode_pubip" {
  count                        = "${var.chef_node_count}"
  name                         = "winnode${count.index}_pubip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "winnode${count.index}-${lower(substr("${join("", split(":", timestamp()))}", 8, -1))}"

  tags {
    environment = "${var.azure_env}"
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "winnode_ip" {
  count               = "${var.chef_node_count}"
  name                = "winnode${count.index}_ip"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "winnode${count.index}_ipconf"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost("10.1.1.20/24", 120+count.index)}"
    public_ip_address_id          = "${element(azurerm_public_ip.winnode_pubip.*.id, count.index + 1)}"
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "winnode" {
  count                 = "${var.chef_node_count}"
  name                  = "winnode${count.index}"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.winnode_ip.*.id, count.index)}"]
  vm_size               = "${var.chef_node_vm_size}"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "winnode${count.index}_osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "winnode${count.index}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  tags {
    environment = "${var.azure_env}"
  }
    os_profile_windows_config {
    provision_vm_agent = true
    }
}
