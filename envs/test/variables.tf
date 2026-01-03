variable "proxmox_node_name" {
  description = "Proxmox Node Name; e.g.: pve1"
  type        = string
}

variable "proxmox_api_endpoint" {
  description = "Proxmox API endpoint; e.g.: https://pve.domain.net:8006"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token; e.g.: USER@pve!provider=TOKEN"
  sensitive   = true
  type        = string
}

variable "root_password_hash" {
  description = "Hashed root password for VMs (generate with: mkpasswd -m sha-512)"
  sensitive   = true
  type        = string
}

variable "vm_datastore_id" {
  description = "Storage for VM disks (e.g., local-zfs, local)"
  type        = string
  default     = "local-zfs"
}
