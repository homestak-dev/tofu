output "zone_id" {
  description = "The SDN zone identifier"
  value       = proxmox_virtual_environment_sdn_zone_vxlan.this.id
}

output "vnet_id" {
  description = "The VNet identifier (use as bridge name for VMs)"
  value       = proxmox_virtual_environment_sdn_vnet.this.id
}

output "subnet_cidr" {
  description = "The subnet CIDR"
  value       = var.subnet_cidr
}

output "gateway" {
  description = "The subnet gateway IP"
  value       = var.subnet_gateway
}
