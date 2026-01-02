locals {
  # PVE test environment - Debian 13 Trixie for testing PVE install
  defaults = {
    proxmox_node_name = "pve"
    bridge            = "vmbr0"
    dns_domain        = "homestak"
    dns_servers       = []
    packages          = []
  }

  node_defaults = {
    vm_id             = null
    mac_address       = null
    ipv4_address      = "dhcp"
    proxmox_node_name = "pve"
  }

  clusters = {
    # Debian 13 Trixie VM for PVE install testing
    pve-test = merge(local.defaults, {
      nodes = {
        1 = merge(local.node_defaults, {
          vm_id   = 99913
          hostname = "debian13"
        })
      }
    })
  }
}
