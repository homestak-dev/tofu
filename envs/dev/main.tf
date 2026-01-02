terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

# SDN - VXLAN overlay network for VM isolation
module "sdn" {
  source         = "../../proxmox-sdn"
  zone_id        = "homestak"
  vnet_id        = "vnet10"
  peers          = ["10.0.12.124"]
  subnet_cidr    = "10.10.10.0/24"
  subnet_gateway = "10.10.10.1"
}

module "common" {
  source   = "../common"
  clusters = local.clusters
}

module "cloud_image" {
  source            = "../../proxmox-file"
  proxmox_node_name = var.proxmox_node_name
  source_file_url   = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

module "nodes_constructor" {
  source = "../../proxmox-vm"

  for_each = module.common.nodes

  cloud_image_id    = module.cloud_image.file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id             = each.value.vm_id
  vm_bridge         = module.sdn.vnet_id
  vm_hostname       = each.value.hostname
  vm_name           = each.value.hostname
  vm_packages       = each.value.packages
  vm_mac_address    = each.value.mac_address
  vm_ipv4_address   = each.value.ipv4_address
  vm_ipv4_gateway   = module.sdn.gateway
  vm_dns_domain     = each.value.dns_domain
  vm_dns_servers    = each.value.dns_servers

  depends_on = [module.sdn]
}
