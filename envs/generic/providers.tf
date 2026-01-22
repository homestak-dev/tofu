terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.93.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.api_endpoint
  api_token = var.api_token
  insecure  = true
  ssh {
    agent       = false
    private_key = file("~/.ssh/id_rsa")
    username    = var.ssh_user
  }
  random_vm_ids = true
  tmp_dir       = "/var/tmp"
}
