variable "proxmox_node_name" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "cloud_image_id" {
  description = "Proxmox file ID for the cloud image"
  type        = string
}

variable "vm_id" {
  description = "VM ID (omit for auto-generated)"
  type        = number
  default     = null
}

variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "vm_tags" {
  description = "List of tags for the VM"
  type        = list(string)
  default     = []
}

variable "vm_memory" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10
}

variable "vm_datastore_id" {
  description = "Datastore for VM disk and cloud-init drive"
  type        = string
  default     = "local-zfs"
}

variable "vm_started" {
  description = "Whether VM should be started after creation"
  type        = bool
  default     = false
}

variable "vm_on_boot" {
  description = "Whether VM should start on host boot"
  type        = bool
  default     = true
}

variable "vm_startup_order" {
  description = "Boot order (lower = earlier)"
  type        = number
  default     = 3
}

# Network configuration - list of NICs
variable "network_devices" {
  description = "List of network devices"
  type = list(object({
    bridge      = string
    mac_address = optional(string)
    vlan_id     = optional(number)
  }))
  default = [{
    bridge = "vmbr0"
  }]
}

# Cloud-init configuration
variable "cloud_init_user_data" {
  description = "Cloud-init user-data (YAML string)"
  type        = string
}

variable "cloud_init_network_data" {
  description = "Cloud-init network-data (YAML string). If not provided, uses Proxmox ip_config."
  type        = string
  default     = null
}

# Used when cloud_init_network_data is not provided
variable "vm_dns_domain" {
  description = "DNS search domain"
  type        = string
  default     = null
}

variable "vm_dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = null
}

variable "vm_ipv4_address" {
  description = "IPv4 address (dhcp or CIDR notation)"
  type        = string
  default     = "dhcp"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway (omit for DHCP)"
  type        = string
  default     = null
}
