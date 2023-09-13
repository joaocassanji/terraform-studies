terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

resource "azurerm_resource_group" "jcassanji-tf-rg" {
  name     = "${var.resource_name_prefix}vm"
  location = var.resource_region
}

resource "azurerm_virtual_network" "jcassanji-tf-vm-vnet" {
  name                = "${var.resource_name_prefix}vm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
}

resource "azurerm_subnet" "jcassanji-tf-vm-vnet-subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.jcassanji-tf-rg.name
  virtual_network_name = azurerm_virtual_network.jcassanji-tf-vm-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "jcassanji-tf-nic" {
  name                = "${var.resource_name_prefix}nic"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jcassanji-tf-vm-vnet-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jcassanji-tf-vm-publicip.id
  }
}

resource "azurerm_linux_virtual_machine" "jcassanji-tf-vm" {
  name                = "${var.resource_name_prefix}vm"
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
  location            = var.resource_region
  size                = var.vm_size
  admin_username      = "jcassanji"
  network_interface_ids = [
    azurerm_network_interface.jcassanji-tf-nic.id,
  ]

  admin_ssh_key {
    username   = "jcassanji"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "jcassanji-tf-nsg" {
  name                = "${var.resource_name_prefix}nsg"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
}

resource "azurerm_network_security_rule" "allow-internet-inbound" {
  name                        = "allow-internet-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.jcassanji-tf-rg.name
  network_security_group_name = azurerm_network_security_group.jcassanji-tf-nsg.name
}

resource "azurerm_network_security_rule" "allow-internet-outbound" {
  name                        = "allow-internet-outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.jcassanji-tf-rg.name
  network_security_group_name = azurerm_network_security_group.jcassanji-tf-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "jcassanji-tf-nsg-association" {
  subnet_id                 = azurerm_subnet.jcassanji-tf-vm-vnet-subnet.id
  network_security_group_id = azurerm_network_security_group.jcassanji-tf-nsg.id
}

resource "azurerm_public_ip" "jcassanji-tf-vm-publicip" {
  name                = "${var.resource_name_prefix}vm-publicip"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "jcassanji-tf-lb-publicip" {
  name                = "${var.resource_name_prefix}lb-publicip"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "jcassanji-tf-lb" {
  name                = "${var.resource_name_prefix}lb"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.jcassanji-tf-lb-publicip.id
  }
}

resource "azurerm_storage_account" "jcassanji-tf-sa" {
  name                     = "jcassanjitfsa"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "jcassanji-tf-sqlserver" {
  name                         = "${var.resource_name_prefix}sqlserver"
  location            = var.resource_region
  resource_group_name = azurerm_resource_group.jcassanji-tf-rg.name
  version                      = "12.0"
  administrator_login          = var.DB_USER
  administrator_login_password = var.DB_PWD
}

resource "azurerm_mssql_database" "jcassanji-tf-sqlserver-db" {
  name           = "jcassanji-tf-sqlserver-db"
  server_id      = azurerm_mssql_server.jcassanji-tf-sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 1
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false

  tags = {
    foo = "bar"
  }
}