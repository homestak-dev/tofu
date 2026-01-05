locals {
  # Nested PVE environment - Debian 13 Trixie VM for PVE installation
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
    # Debian 13 Trixie VM for PVE installation
    nested-pve = merge(local.defaults, {
      nodes = {
        1 = merge(local.node_defaults, {
          vm_id    = 99913
          hostname = "nested-pve"
        })
      }
    })
  }
}
