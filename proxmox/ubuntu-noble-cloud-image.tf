resource "proxmox_virtual_environment_file" "ubuntu_noble_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve1"

  source_file {
    path     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    checksum = "63f5e103195545a429aec2bf38330e28ab9c6d487e66b7c4b0060aa327983628"
  }
}

