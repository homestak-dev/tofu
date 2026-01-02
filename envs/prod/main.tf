terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

module "common" {
  source  = "../common"
  clusters = local.clusters
}

module "cloud_image" {
  source = "../../proxmox-file"
}

module "nodes_constructor" {
  source = "../../proxmox-vm"

  for_each         = module.common.nodes

  cloud_image_id   = module.cloud_image.file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id            = each.value.vm_id
  vm_bridge        = each.value.bridge
  vm_hostname      = each.value.hostname
  vm_name          = each.value.hostname
  vm_packages      = each.value.packages
  vm_mac_address   = each.value.mac_address
  vm_ipv4_address  = each.value.ipv4_address
  vm_ipv4_gateway  = each.value.ipv4_gateway
  vm_dns_domain    = each.value.dns_domain
  vm_dns_servers   = each.value.dns_servers
}
