output "vm_public_key" {
  value = tls_private_key.this.public_key_openssh
}

output "vm_network_device" {
  value = proxmox_virtual_environment_vm.this.network_device
}
