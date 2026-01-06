# Module: proxmox-sdn
# Configures VXLAN SDN for VM network isolation.
#
# Creates zone, vnet, subnet, and applies config to all PVE nodes.
# Currently not integrated into iac-driver workflows (see iac-driver#28).
#
# Inputs: zone_id, vnet_id, peers, subnet_cidr, subnet_gateway
# Outputs: zone_id, vnet_id, subnet_cidr, gateway

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# VXLAN Zone - overlay network for VM traffic
resource "proxmox_virtual_environment_sdn_zone_vxlan" "this" {
  id    = var.zone_id
  peers = var.peers
  mtu   = var.mtu
}

# VNet - virtual network attached to the zone
resource "proxmox_virtual_environment_sdn_vnet" "this" {
  id   = var.vnet_id
  zone = proxmox_virtual_environment_sdn_zone_vxlan.this.id
  tag  = var.vxlan_tag
}

# Subnet - IP addressing for the VNet
resource "proxmox_virtual_environment_sdn_subnet" "this" {
  cidr    = var.subnet_cidr
  vnet    = proxmox_virtual_environment_sdn_vnet.this.id
  gateway = var.subnet_gateway
}

# Applier - commits SDN configuration to all nodes
resource "proxmox_virtual_environment_sdn_applier" "this" {
  depends_on = [
    proxmox_virtual_environment_sdn_zone_vxlan.this,
    proxmox_virtual_environment_sdn_vnet.this,
    proxmox_virtual_environment_sdn_subnet.this,
  ]

  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_sdn_zone_vxlan.this,
      proxmox_virtual_environment_sdn_vnet.this,
      proxmox_virtual_environment_sdn_subnet.this,
    ]
  }
}
