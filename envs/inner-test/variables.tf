variable "proxmox_node_name" {
  description = "Proxmox Node Name (inner PVE)"
  type        = string
  default     = "debian13"
}

variable "proxmox_api_endpoint" {
  description = "Proxmox API endpoint; e.g.: https://debian13:8006"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token; e.g.: root@pam!tofu=TOKEN"
  sensitive   = true
  type        = string
}

variable "root_password_hash" {
  description = "Hashed root password for VMs (generate with: mkpasswd -m sha-512)"
  sensitive   = true
  type        = string
}
