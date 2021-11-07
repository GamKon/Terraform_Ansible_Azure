# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

# Remote state in Terraform_remotestate_storage/tfremotestategamkon/kg-tf-state/Terraform_Ansible_Azure
terraform {
  backend "azurerm" {
    resource_group_name  = "Terraform_remotestate_storage"
    storage_account_name = "tfremotestategamkon"
    container_name       = "kg-tf-state"
    key                  = "Terraform_Ansible_Azure/terraform.tfstate"
  }
}

resource "azurerm_resource_group" "example_app_rg" {
  name     = "example-app-rg"
  location = "Canada Central"
}

resource "azurerm_public_ip" "example_app_pubip" {
  name                = "example-app-pubip"
  resource_group_name = azurerm_resource_group.example_app_rg.name
  location            = azurerm_resource_group.example_app_rg.location
  allocation_method   = "Dynamic"
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_virtual_network" "example_app_vnet" {
  name                = "example-app-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example_app_rg.location
  resource_group_name = azurerm_resource_group.example_app_rg.name
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "example_app_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example_app_rg.name
  virtual_network_name = azurerm_virtual_network.example_app_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example_app_nic" {
  name                = "example-app-nic"
  location            = azurerm_resource_group.example_app_rg.location
  resource_group_name = azurerm_resource_group.example_app_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example_app_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example_app_pubip.id
  }
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_linux_virtual_machine" "vm_1" {
  name                = "vm-1"
  resource_group_name = azurerm_resource_group.example_app_rg.name
  location            = azurerm_resource_group.example_app_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example_app_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "Dev"
  }
}
