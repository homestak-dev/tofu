terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

provider "proxmox" {
  # https://registry.terraform.io/providers/bpg/proxmox/latest/docs
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  ssh {
    agent       = false
    private_key = file("~/.ssh/id_rsa")
    username    = "jderose"
  }
  random_vm_ids = true
  tmp_dir = "/var/tmp"
}
