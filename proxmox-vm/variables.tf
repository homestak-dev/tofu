variable "proxmox_node_name" {
  description = "Proxmox Node Name; e.g.: pve1"
  default = "pve1"
  type = string
}

variable "cloud_image_id" {
  description = ""
  type = string
}

variable "vm_name" {
  description = "internal name for the virtual machine; e.g.: web1"
  type = string
}

variable "vm_hostname" {
  description = "hostname for the virtual machine; e.g.: web1"
  type = string
}

variable "vm_tags" {
  description = "list of tags for the virtual machine; e.g.: [\"dev\",\"ubuntu\"]"
  default = null
  type = list(string)
}

variable "vm_bridge" {
  description = "bridge interface for the virtual machine; e.g.: jderose.net"
  default = "vmbr0"
  type = string
}

variable "vm_dns_domain" {
  description = "dns search domain for the virtual machine; e.g.: jderose.net"
  default = null
  type = string
}

variable "vm_dns_servers" {
  description = "list of dns server(s) for the virtual machine; e.g.: [\"10.0.12.1\"]"
  default = null
  type = list(string)
}

variable "vm_ipv4_address" {
  description = "ipv4 address for the virtual machine; e.g.: dhcp, 10.0.12.100"
  default = "dhcp"
  type = string
}

variable "vm_ipv4_gateway" {
  description = "ipv4 gateway for the virtual machine (omit for dhcp); e.g.: 10.0.12.1"
  default = null
  type = string
}

variable "vm_packages" {
  description = "optional packages for the virtual machine; e.g., [\"curl\",\"git\"]"
  default = [ ]
  type = list(string)
}

variable "vm_vlan_id" {
  description = "vlan id for the virtual machine (omit for untagged); e.g.: 12"
  default = null
  type = string
}
