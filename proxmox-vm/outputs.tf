output "vm_id" {
  value = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.this.name
}

output "vm_ipv4_addresses" {
  value = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "vm_mac_addresses" {
  value = proxmox_virtual_environment_vm.this.mac_addresses
}
