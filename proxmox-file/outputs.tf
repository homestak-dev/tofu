output "file_id" {
  value = var.source_type == "url" ? proxmox_virtual_environment_download_file.this[0].id : var.local_file_id
}

output "file_name" {
  value = var.source_type == "url" ? proxmox_virtual_environment_download_file.this[0].file_name : var.local_file_id
}
