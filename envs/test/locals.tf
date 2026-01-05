locals {
  # Simple test environment on vmbr0 (no SDN)
  defaults = {
    proxmox_node_name = module.config.node
    bridge            = "vmbr0"
    dns_domain        = module.config.domain
    dns_servers       = []
    packages          = []
  }

  node_defaults = {
    vm_id             = null
    mac_address       = null
    ipv4_address      = "dhcp"
    proxmox_node_name = module.config.node
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
