# Module: proxmox-file
# Manages cloud images for VM provisioning.
#
# Supports two modes:
# - local: Uses pre-staged images (e.g., packer-built)
# - url: Downloads images from remote source
#
# Inputs: source_type, local_file_id or url/path/checksum
# Outputs: file_id, file_name

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_download_file.md
resource "proxmox_virtual_environment_download_file" "this" {
  count = var.source_type == "url" ? 1 : 0

  content_type        = "iso"
  datastore_id        = "local"
  node_name           = var.proxmox_node_name
  url                 = var.source_file_url
  file_name           = var.source_file_path
  checksum            = var.source_file_checksum_val
  checksum_algorithm  = var.source_file_checksum_algo
  overwrite_unmanaged = true
}

