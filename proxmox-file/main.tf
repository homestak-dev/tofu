terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_download_file.md
resource "proxmox_virtual_environment_download_file" "this" {
  content_type       = "iso"
  datastore_id       = "cephfs"
  node_name          = var.proxmox_node_name
  url                = var.source_file_url
  checksum           = var.source_file_checksum_val
  checksum_algorithm = var.source_file_checksum_algo
  overwrite_unmanaged= true
}

