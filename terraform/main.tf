resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "random_string" "random_string" {
  length  = 5
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  # name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_public_ip" "pip_azfw" {
  name                = "pip-azfw-${random_string.random_string.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_storage_account" "sa" {
  name                     = random_string.random_string.result
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_virtual_network" "azfw_vnet" {
  name                = "azfw-${random_string.random_string.result}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.virtual_network_address_space
}

resource "azurerm_subnet" "azfw_default_subnet" {
  name                 = "avd-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = var.avd_subnet_address_prefix
}

resource "azurerm_subnet" "azfw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = var.firewall_subnet_address_prefix
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = var.gateway_subnet_address_prefix
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = var.bastion_subnet_address_prefix
}

resource "azurerm_subnet" "vpn_overlay_subnet" {
  name                 = "VpnOverlaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = var.vpn_overlay_subnet_address_prefix
}

resource "azurerm_firewall_policy" "azfw_policy" {
  name                     = "azfw-${random_string.random_string.result}-policy"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Alert"
  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "prcg" {
  name               = "prcg"
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
  priority           = 300
  application_rule_collection {
    name     = "avd_rule_collection"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "TelemetryService"
      protocols             {
        type = "Https"
        port = 443
      }
      source_addresses      = var.avd_subnet_address_prefix
      destination_fqdns     = ["*.events.data.microsoft.com"]
      }
  
    rule {
      name                  = "WindowsUpdate"
      protocols             {
        type = "Https"
        port = 443
      }
      source_addresses      = var.avd_subnet_address_prefix
      destination_fqdns = ["WindowsUpdate"]
      }
  
    rule {
      name                  = "UpdatesForOneDrive"
      protocols             {
        type = "Https"
        port = 443
      }
      source_addresses      = var.avd_subnet_address_prefix
      destination_fqdns     = ["*.sfx.ms"]
      }
  
    rule {
      name                  = "DigitcertCRL"
      protocols             {
        type = "Https"
        port = 443
      }
      source_addresses      = var.avd_subnet_address_prefix
      destination_fqdns     = ["*.digicert.com"]
      }
  
    rule {
      name                  = "AzureDNSresolution1"
      protocols             {
        type = "Https"
        port = 443
      }
      source_addresses      = var.avd_subnet_address_prefix
      destination_fqdns     = ["*.azure-dns.com"]
      }
  
    rule {
      name                  = "AzureDNSresolution2"
      protocols             {
        type = "Https"
        port = 443
      }
      source_addresses      = var.avd_subnet_address_prefix
      destination_fqdns     = ["*.azure-dns.net"]
      }
  }
  network_rule_collection {
    name     = "netRc1"
    priority = 100
    action   = "Allow"
    
      rule {
        name                  = "Service Traffic"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_addresses = ["WindowsVirtualDesktop"]
        destination_ports     = ["443"]
        }
    
      rule {
        name                  = "Agent Traffic (1)"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_addresses = ["AzureMonitor"]
        destination_ports     = ["443"]
        }
    
      rule { 
        name                  = "Agent Traffic (2)"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["443"]
        destination_fqdns      = ["gcs.prod.monitoring.core.windows.net"]
        }
    
      rule {
        name                  = "Azure Marketplace"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_addresses = ["AzureFrontDoor.Frontend"]
        destination_ports     = ["443"]
        }
    
      rule {
        name                  = "Windows activation"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["1688"]
        destination_fqdns      = ["kms.core.windows.net"]
        }
    
      rule {
        name                  = "Azure Windows activation"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["1688"]
        destination_fqdns      = ["azkms.core.windows.net"]
        }
    
      rule {
        name                  = "Agent and SXS Stack Updates"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["443"]
        destination_fqdns      = ["mrsglobalsteus2prod.blob.core.windows.net"]
        }
    
      rule {
        name                  = "Azure Portal Support"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["443"]
        destination_fqdns      = ["wvdportalstorageblob.blob.core.windows.net"]
        }
    
      rule {
        name                  = "Azure Instance Metadata Service Endpoint"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_addresses = ["169.254.169.254"]
        destination_ports     = ["80"]
        
        }
    
      rule {
        name                  = "Session Host Health Monitoring"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_addresses = ["168.63.129.16"]
        destination_ports     = ["80"]
        
        }
    
      rule {
        name                  = "Certificate CRL OneOCSP"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["80"]
        destination_fqdns      = ["oneocsp.microsoft.com"]
        }
    
      rule {
        name                  = "Certificate CRL MicrosoftDotCom"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["80"]
        destination_fqdns      = ["www.microsoft.com"]
        }
    
      rule {
        name                  = "Authentication to Microsoft Online Services"
        protocols             = ["TCP"]
        source_addresses      = var.avd_subnet_address_prefix
        destination_ports     = ["443"]
        destination_fqdns      = ["login.microsoftonline.com"]
        }
  }
}

resource azurerm_firewall_policy_rule_collection_group "fw_rcg" {
  name                = "overlay_rule_collection"
  firewall_policy_id  = azurerm_firewall_policy.azfw_policy.id
  priority            = 200
  network_rule_collection {
    name = "network-rule-collection"
    priority = 300
    action = "Allow"
    rule {
      name                  = "overlay_tcp"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = var.vpn_overlay_subnet_address_prefix
      destination_ports     = ["80", "443", "33073", "10000"]
    }
    rule {
      name                  = "overlay_udp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = var.vpn_overlay_subnet_address_prefix
      destination_ports     = ["3478", "49152-65535"]
    }
  }
}

# module "fw_rcg" {
#   source = "./modules/fw_rcg"
#   firewall_policy_rule_collection_group_name = "overlay_rule_collection"
#   firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
#   priority = 400
#   destination_addresses = var.vpn_overlay_subnet_address_prefix
#   depends_on = [azurerm_firewall_policy_rule_collection_group.prcg]
# }

resource "azurerm_firewall" "fw" {
  name                = "azfw-${random_string.random_string.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  ip_configuration {
    name                 = "azfw-${random_string.random_string.result}-ipconfig"
    subnet_id            = azurerm_subnet.azfw_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_azfw.id
  }
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
}

resource "azurerm_route_table" "rt" {
  name                          = "rt-azfw-${random_string.random_string.result}-eus"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false
  route {
    name                   = "azfwDefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
  route {
    name                   = "API"
    address_prefix         = "ApiManagement"
    next_hop_type          = "Internet"
  }
  route {
    name                   = "AVDServiceTag"
    address_prefix         = "WindowsVirtualDesktop"
    next_hop_type          = "Internet"
  }
  route {
    name                   = "BlobAccess"
    address_prefix         = "Storage"
    next_hop_type          = "Internet"
  }
  route {
    name                   = "Entra"
    address_prefix         = "AzureActiveDirectory"
    next_hop_type          = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "avd_subnet_rt_association" {
  subnet_id      = azurerm_subnet.azfw_default_subnet.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_subnet_route_table_association" "overlay_subnet_rt_association" {
  subnet_id      = azurerm_subnet.vpn_overlay_subnet.id
  route_table_id = azurerm_route_table.rt.id
}
