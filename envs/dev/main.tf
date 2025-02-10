terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

module "common" {
  source  = "../common"
  clusters = local.clusters
}

module "cloud_image" {
  source = "../../proxmox-file"
  source_file_url = "https://mirror.sfo12.us.leaseweb.net/opnsense/releases/mirror/OPNsense-25.1-dvd-amd64.iso.bz2"
}

module "create_opnsense_vm" {
  source = "../../proxmox-vm"

  cloud_image_id   = module.cloud_image.file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id            = "10001"
  vm_bridge        = "vnet10"
  vm_hostname      = "opnsense"
  vm_name          = "opnsense"
  vm_packages      = null
  vm_mac_address   = "BC:24:11:BA:76:05"
  vm_ipv4_address  = "10.10.10.1"
  vm_ipv4_gateway  = null
  vm_dns_domain    = null
  vm_dns_servers   = null
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
