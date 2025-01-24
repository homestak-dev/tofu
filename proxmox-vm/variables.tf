variable "proxmox_node_name" {
  description = "Proxmox Node Name; e.g.: pve1"
  default = "pve1"
  type = string
}

variable "source_file_path" {
  description = "local path to cloud image (not .iso)"
  default = "noble-server-cloudimg-amd64.img"
  type = string
}

variable "source_file_url" {
  description = "remote url to cloud image (not .iso)"
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  type = string
}

variable "source_file_checksum" {
  description = "SHA-256 checksum for cloud image file"
  default = "63f5e103195545a429aec2bf38330e28ab9c6d487e66b7c4b0060aa327983628"
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
  default = [ ]
  type = list(string)
}

variable "vm_dns_domain" {
  description = "dns search domain for the virtual machine; e.g.: jderose.net"
  default = null
  type = string
}

variable "vm_dns_servers" {
  description = "list of dns server(s) for the virtual machine; e.g.: [\"10.0.12.1\"]"
  default = [ ]
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

variable "vm_vlan_id" {
  description = "vlan id for the virtual machine (omit for untagged); e.g.: 12"
  default = null
  type = string
}

