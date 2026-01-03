provider "proxmox" {
  # Targets inner PVE instance (debian13)
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  ssh {
    agent       = false
    private_key = file("~/.ssh/id_rsa")
    username    = "root"
  }
  random_vm_ids = true
  tmp_dir       = "/var/tmp"
}
