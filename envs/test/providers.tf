provider "proxmox" {
  # https://search.opentofu.org/provider/bpg/proxmox/latest
  # https://github.com/bpg/terraform-provider-proxmox
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  ssh {
    agent       = false
    private_key = file("~/.ssh/id_rsa")
    username    = var.ssh_user
  }
  random_vm_ids = true
  tmp_dir       = "/var/tmp"
}
