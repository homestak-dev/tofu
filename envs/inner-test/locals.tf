locals {
  # Test environment for inner PVE (debian13)
  defaults = {
    proxmox_node_name = "debian13"
    bridge            = "vmbr0"
    dns_domain        = "inner.local"
    dns_servers       = []
    packages          = []
  }

  node_defaults = {
    vm_id             = null
    mac_address       = null
    ipv4_address      = "dhcp"
    proxmox_node_name = "debian13"
  }

  clusters = {
    # Single test VM on inner PVE
    test = merge(local.defaults, {
      nodes = {
        1 = merge(local.node_defaults, {
          vm_id    = 100
          hostname = "test1"
        })
      }
    })
  }
}
