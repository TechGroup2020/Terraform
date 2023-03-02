provider "azurerm" {
  
  subscription_id = "c29e8d9b-1f59-47dc-a1e0-97e6b3a39fd5"  
  tenant_id       = "848eca09-f730-4a7c-818a-a68a010ddd50"  
  client_id       = "7a1b822c-9ff5-49e9-9404-460e748dacab"
  client_secret   = "6151df76-330a-4662-bc8b-867a231217ff"
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "vid-RG11" {
  name     = "vid-RG11"
  location = "eastus"
  }


# Create virtual network
resource "azurerm_virtual_network" "vid-vnet1" {
  name                = "vid-vnet"
  address_space       = ["10.172.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.vid-RG11.name
}
# Create subnet
resource "azurerm_subnet" "vid-sub1" {

  name                 = "vid-subnet"
  resource_group_name  = azurerm_resource_group.vid-RG11.name
  virtual_network_name = azurerm_virtual_network.vid-vnet1.name
  address_prefixes     = ["10.172.4.0/24"]
}
# Create public IPs
resource "azurerm_public_ip" "vid-pip1" {
  for_each            = var.instences
  name                = "vid-pub-${each.key}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.vid-RG11.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vid-sg1" {
  name                = "vid-NSG"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.vid-RG11.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
} 
resource "azurerm_network_interface" "staticnic" {
  for_each            = var.instences
  name                = "vidstatic-NIC-${each.key}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.vid-RG11.name

  ip_configuration {

    name                          = "monitoringConfg"
    subnet_id                     = azurerm_subnet.vid-sub1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.IP_address
    public_ip_address_id          = azurerm_public_ip.vid-pip1[each.key].id

  }
}

resource "azurerm_subnet_network_security_group_association" "vid-asso1" {
  subnet_id                 = azurerm_subnet.vid-sub1.id
  network_security_group_id = azurerm_network_security_group.vid-sg1.id
}


resource "azurerm_virtual_machine" "vid-vm1" {
  for_each                        = var.instences
  name                            = "vid-${each.key}"
  location                        = "eastus"
  resource_group_name             = azurerm_resource_group.vid-RG11.name
  network_interface_ids           = [azurerm_network_interface.staticnic[each.key].id]
  vm_size                         = "Standard_D2S_v3"
  
  
     
  storage_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "18.04-LTS"
     version   = "latest"
   }

  storage_os_disk {
     name              = "myosdisk${each.key}"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }
  
  os_profile {
     computer_name  = "hostname"
     admin_username = "testadmin"
     admin_password = "Password1234!"
   }

  os_profile_linux_config {
     disable_password_authentication = false
   }



}
