resource azurerm_firewall_policy_rule_collection_group "fw_rcg" {
  name                = var.firewall_policy_rule_collection_group_name
  firewall_policy_id  = var.firewall_policy_id
  priority            = var.priority
  network_rule_collection {
    name = "network-rule-collection"
    priority = 300
    action = "Allow"
    rule {
      name                  = "overlay_tcp"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = var.destination_addresses
      destination_ports     = ["80", "443", "33073", "10000"]
    }
    rule {
      name                  = "overlay_udp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = var.destination_addresses
      destination_ports     = ["3478", "49152-65535"]
    }
  }
}