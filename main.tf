provider "azurerm" {
  #alias = "testname"
  subscription_id = "aceff81f-39b5-4d42-ab2b-d2f250610e7e"
  client_id       = "9cb2f04e-1dd7-4a14-857f-99f6944e2439"
  client_secret   = "Nyg8Q~NWaQ-f4A5BBBJmzMXnPVB9YbBl-5EzJdet"
  tenant_id       = "57c28b3a-e951-477f-a598-a49249f793a3"  
  features {}
}

# Create a resource group if it doesn't exist
data "azurerm_resource_group" "vid-RG11" {
  name     = "vid-RG11"
  #location = "eastus"
}

data "azurerm_image" "main" {
  #provider            =  azurerm.testname 
  name                = "Ubuntu-project30"
  resource_group_name = "vid-RG11"
  #location            = "eastus"
}



# Create virtual network
resource "azurerm_virtual_network" "vid-vnet1" {
  name                = "vid-vnet"
  address_space       = ["10.172.0.0/16"]
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.vid-RG11.name
}
# Create subnet
resource "azurerm_subnet" "vid-sub1" {

  name                 = "vid-subnet"
  resource_group_name  = data.azurerm_resource_group.vid-RG11.name
  virtual_network_name = azurerm_virtual_network.vid-vnet1.name
  address_prefixes     = ["10.172.4.0/24"]
}
# Create public IPs
resource "azurerm_public_ip" "vid-pip1" {
  for_each            = var.instences
  name                = "vid-pub-${each.key}"
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.vid-RG11.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vid-sg1" {
  name                = "vid-NSG"
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.vid-RG11.name

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
  resource_group_name = data.azurerm_resource_group.vid-RG11.name

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
  resource_group_name             = data.azurerm_resource_group.vid-RG11.name
  network_interface_ids           = [azurerm_network_interface.staticnic[each.key].id]
  vm_size                         = "Standard_D2S_v3"
  #admin_username                  = "vidadmin"
  #admin_password                  = "Password@123"
  #admin_password                  = azurerm_key_vault_secret.vid-sec.value
  #disable_password_authentication = false
  
  storage_image_reference {
    id = "/subscriptions/aceff81f-39b5-4d42-ab2b-d2f250610e7e/resourceGroups/vid-RG11/providers/Microsoft.Compute/images/Ubuntu-project30"

  }
  /*plan{
  name = "cloude"
  product = "cloudeteer"
  publisher = "cloudeteer"
}*/
   
  storage_os_disk {
    name                 = "viddisk-${each.key}"
    caching              = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    disk_size_gb         = each.value.disk
    create_option        = "FromImage"
    }

    os_profile {
      computer_name  = "testvm"
      admin_username = "vidadmin"

      admin_password = "Password@123"
      
    }
    os_profile_linux_config {
      disable_password_authentication = false

    }

 
   
  
  /*source_image_reference {
    publisher = "Canonical"
    offer     = "Ubuntu-project30"
    sku       = "18.04-LTS"
    version   = "latest"
  }*/
}

