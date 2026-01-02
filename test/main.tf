terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

module "cloud_image" {
  source = "../proxmox-file"
}

module "test_vm" {
  source = "../proxmox-vm"
  count  = 1      # set this to 1 to enable, 0 to disable

  # required values
  cloud_image_id  = module.cloud_image.file_id
  vm_name         = "TofuTestVM"
  vm_hostname     = "tofutest"
}

