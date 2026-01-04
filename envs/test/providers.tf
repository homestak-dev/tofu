provider "proxmox" {
  # https://search.opentofu.org/provider/bpg/proxmox/latest
  # https://github.com/bpg/terraform-provider-proxmox
  endpoint  = module.config.api_endpoint
  api_token = module.config.api_token
  insecure  = true
  ssh {
    agent       = false
    private_key = file("~/.ssh/id_rsa")
    username    = module.config.ssh_user
  }
  random_vm_ids = true
  tmp_dir       = "/var/tmp"
}
