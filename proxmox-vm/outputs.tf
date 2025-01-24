output "vm_public_key" {
  value = tls_private_key.this.public_key_openssh
}

