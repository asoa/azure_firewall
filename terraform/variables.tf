variable "resource_group_location" {
  type        = string
  description = "Location for all resources."
  default     = "usgovvirginia"
}

variable "resource_group_name_prefix" {
  type        = string
  description = "Prefix for the Resource Group Name that's combined with a random id so name is unique in your Azure subcription."
  default     = "hack"
}

# variable "resource_group_name" {
#   type        = string
#   description = "Name of the Resource Group; use for hackathon"
# }

variable "firewall_sku_tier" {
  type        = string
  description = "Firewall SKU."
  default     = "Standard" # Valid values are Standard and Premium
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "The SKU must be one of the following: Standard, Premium"
  }
}

variable "virtual_machine_size" {
  type        = string
  description = "Size of the virtual machine."
  default     = "Standard_D2_v3"
}

variable "admin_username" {
  type        = string
  description = "Value of the admin username."
}

variable "virtual_network_address_space" {
  type        = list(string)
  description = "Address space for the virtual network."
}

variable "avd_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the AVD subnet."
}

variable "firewall_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the Firewall subnet."
}

variable "gateway_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the Gateway subnet."
}

variable "bastion_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the Bastion subnet."
}

variable "vpn_overlay_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the VPN Overlay subnet."
}