output "vm_ips" {
  description = "Map of VM names to their IPv4 addresses"
  value       = { for k, v in module.vm : k => v.vm_ipv4_addresses }
}

output "vm_ids" {
  description = "Map of VM names to their VM IDs"
  value       = { for k, v in module.vm : k => v.vm_id }
}
