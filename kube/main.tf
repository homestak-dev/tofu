terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

module "cloud_image" {
  source = "../proxmox-file"
}

module "k3s_mgmt" {
  source = "../proxmox-vm"
  count  = 3      # set this >= 1 to enable, 0 to disable

  # required values
  cloud_image_id  = module.cloud_image.file_id
  vm_name         = "mgmt${count.index+1}.kube"
  vm_hostname     = "mgmt${count.index+1}"

  # optional values
  vm_tags         = ["k3s","mgmt","tofu","ubuntu"]
  vm_dns_domain   = "kube.jderose.net"
  vm_dns_servers  = ["10.0.30.1"]
  vm_ipv4_address = "10.0.30.10${count.index+1}/24"
  vm_ipv4_gateway = "10.0.30.1"
  vm_vlan_id      = "30"
}

module "k3s_prod" {
  source = "../proxmox-vm"
  count  = 6      # set this >= 1 to enable, 0 to disable

  # required values
  cloud_image_id  = module.cloud_image.file_id
  vm_name         = "prod${count.index+1}.kube"
  vm_hostname     = "prod${count.index+1}"

  # optional values
  vm_tags         = ["k3s","prod","tofu","ubuntu"]
  vm_dns_domain   = "kube.jderose.net"
  vm_dns_servers  = ["10.0.32.1"]
  vm_ipv4_address = "10.0.32.10${count.index+1}/24"
  vm_ipv4_gateway = "10.0.32.1"
  vm_vlan_id      = "32"
}

module "k3s_stg" {
  source = "../proxmox-vm"
  count  = 6      # set this >= 1 to enable, 0 to disable

  # required values
  cloud_image_id  = module.cloud_image.file_id
  vm_name         = "stg${count.index+1}.kube"
  vm_hostname     = "stg${count.index+1}"

  # optional values
  vm_tags         = ["k3s","stg","tofu","ubuntu"]
  vm_dns_domain   = "kube.jderose.net"
  vm_dns_servers  = ["10.0.34.1"]
  vm_ipv4_address = "10.0.34.10${count.index+1}/24"
  vm_ipv4_gateway = "10.0.34.1"
  vm_vlan_id      = "34"
}

module "k3s_test" {
  source = "../proxmox-vm"
  count  = 3      # set this >= 1 to enable, 0 to disable

  # required values
  cloud_image_id  = module.cloud_image.file_id
  vm_name         = "test${count.index+1}.kube"
  vm_hostname     = "test${count.index+1}"

  # optional values
  vm_tags         = ["k3s","test","tofu","ubuntu"]
  vm_dns_domain   = "kube.jderose.net"
  vm_dns_servers  = ["10.0.36.1"]
  vm_ipv4_address = "10.0.36.10${count.index+1}/24"
  vm_ipv4_gateway = "10.0.36.1"
  vm_vlan_id      = "36"
}

module "k3s_dev" {
  source = "../proxmox-vm"
  count  = 3      # set this >= 1 to enable, 0 to disable

  # required values
  cloud_image_id  = module.cloud_image.file_id
  vm_name         = "dev${count.index+1}.kube"
  vm_hostname     = "dev${count.index+1}"

  # optional values
  vm_tags         = ["k3s","dev","tofu","ubuntu"]
  vm_dns_domain   = "kube.jderose.net"
  vm_dns_servers  = ["10.0.38.1"]
  vm_ipv4_address = "10.0.38.10${count.index+1}/24"
  vm_ipv4_gateway = "10.0.38.1"
  vm_vlan_id      = "38"
}

