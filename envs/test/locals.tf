locals {
  # Simple test environment on vmbr0 (no SDN)
  defaults = {
    proxmox_node_name = "pve"
    bridge            = "vmbr0"
    dns_domain        = "test.local"
    dns_servers       = ["8.8.8.8", "1.1.1.1"]
    packages          = []
  }

  node_defaults = {
    vm_id             = null
    mac_address       = null
    ipv4_address      = "dhcp"
    proxmox_node_name = "pve"
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
