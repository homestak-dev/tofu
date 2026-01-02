locals {

  defaults = {
    proxmox_node_name = "pve"
    bridge            = "vnet10"
    dns_domain        = "homestak"
    dns_servers       = ["10.10.10.1"]
    ipv4_gateway      = "10.10.10.1"
    packages          = ["git", "net-tools"]
  }

  clusters = {
    dev = merge(local.defaults, {
        nodes = {
        1 = { mac_address = null, ipv4_address = "dhcp", vm_id = "10001", proxmox_node_name = "pve" }
        }
      }
    )
  }

}
