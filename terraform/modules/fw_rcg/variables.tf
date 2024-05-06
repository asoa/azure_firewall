variable "destination_addresses" {
   description = "The destination addresses for the firewall rule"
   type        = list(string)
   default     = ["*"]
}

variable "firewall_policy_id" {
  type        = string
  description = "ID of the Firewall Policy."
}

variable "firewall_policy_rule_collection_group_name" {
  type        = string
  description = "Name of the Firewall Policy Rule Collection Group."
  default     = "fw-rcg"
} 

variable "priority" {
  type        = number
  description = "Priority of the Firewall Policy Rule Collection Group."
}

variable "destination_addresses" {
  type        = list(string)
  description = "Destination addresses for the network rule collection."
}

