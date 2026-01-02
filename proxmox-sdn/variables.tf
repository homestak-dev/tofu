variable "zone_id" {
  description = "SDN zone identifier; e.g.: homestak"
  type        = string
}

variable "vnet_id" {
  description = "VNet identifier; e.g.: vnet10"
  type        = string
}

variable "peers" {
  description = "List of Proxmox node IPs for VXLAN tunnel endpoints"
  type        = set(string)
}

variable "subnet_cidr" {
  description = "Subnet CIDR for the VNet; e.g.: 10.10.10.0/24"
  type        = string
}

variable "subnet_gateway" {
  description = "Gateway IP for the subnet; e.g.: 10.10.10.1"
  type        = string
}

variable "mtu" {
  description = "MTU for VXLAN (should be underlay MTU minus 50 for VXLAN overhead)"
  type        = number
  default     = 1450
}

variable "vxlan_tag" {
  description = "VXLAN Network Identifier (VNID) - unique tag for this virtual network"
  type        = number
  default     = 100
}

