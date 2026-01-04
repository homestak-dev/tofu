# Config-loader module outputs
# Provides merged configuration for providers and resources

# Identity
output "env" {
  description = "Environment name"
  value       = local.merged.env
}

output "node" {
  description = "PVE node name"
  value       = local.merged.node
}

# API configuration (for proxmox provider)
output "api_endpoint" {
  description = "Proxmox API endpoint URL"
  value       = local.merged.api_endpoint
}

output "api_token" {
  description = "Proxmox API token"
  value       = local.merged.api_token
  sensitive   = true
}

# Node properties
output "host" {
  description = "Physical host name (FK to hosts/)"
  value       = local.merged.host
}

output "parent_node" {
  description = "Parent PVE node for nested PVE"
  value       = local.merged.parent_node
}

output "node_ip" {
  description = "IP address of the PVE node"
  value       = local.merged.node_ip
}

# Storage and defaults
output "datastore" {
  description = "Default datastore for VMs"
  value       = local.merged.datastore
}

output "ssh_user" {
  description = "SSH user for provider connection"
  value       = local.merged.ssh_user
}

output "domain" {
  description = "Default DNS domain"
  value       = local.merged.domain
}

output "timezone" {
  description = "Default timezone"
  value       = local.merged.timezone
}

# Secrets
output "root_password" {
  description = "Hashed root password for VMs"
  value       = local.merged.root_password
  sensitive   = true
}

output "ssh_keys" {
  description = "List of SSH public keys"
  value       = local.merged.ssh_keys
  sensitive   = true
}

# Full merged config (for debugging/advanced use)
output "config" {
  description = "Full merged configuration object"
  value       = local.merged
  sensitive   = true
}
