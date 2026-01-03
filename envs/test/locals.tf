locals {
  # Simple test environment on vmbr0 (no SDN)
  defaults = {
    proxmox_node_name = var.proxmox_node_name
    bridge            = "vmbr0"
    dns_domain        = "test.local"
    dns_servers       = []
    packages          = []
  }

  node_defaults = {
    vm_id             = null
    mac_address       = null
    ipv4_address      = "dhcp"
    proxmox_node_name = var.proxmox_node_name
  }

  clusters = {
    # Single test VM - toggle count in main.tf to enable/disable
    test = merge(local.defaults, {
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 99901 })
      }
    })
  }
}
