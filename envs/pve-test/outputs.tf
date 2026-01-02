output "vm_ips" {
  description = "IP addresses of created VMs"
  value       = { for k, v in module.vm : k => v.vm_ipv4_addresses }
}
