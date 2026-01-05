# Generic environment variables
# All values resolved by iac-driver's ConfigResolver

variable "node" {
  description = "Target PVE node name"
  type        = string
}

variable "api_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "SSH user for provisioning"
  type        = string
  default     = "root"
}

variable "datastore" {
  description = "Default datastore for VMs"
  type        = string
  default     = "local-zfs"
}

variable "root_password" {
  description = "Root password hash for cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "SSH public keys for cloud-init"
  type        = list(string)
  sensitive   = true
}

variable "vms" {
  description = "List of VMs to create (resolved by iac-driver)"
  type = list(object({
    name     = string
    vmid     = optional(number)
    image    = string
    cores    = number
    memory   = number
    disk     = number
    bridge   = optional(string, "vmbr0")
    ip       = optional(string, "dhcp")
    packages = optional(list(string), [])
  }))
}

# Image name to Proxmox file ID mapping
variable "images" {
  description = "Map of image names to Proxmox file IDs"
  type        = map(string)
  default = {
    "debian-12" = "local:iso/debian-12-custom.img"
    "debian-13" = "local:iso/debian-13-custom.img"
  }
}
