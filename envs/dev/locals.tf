locals {

  defaults = {
    proxmox_node_name = null              # explicitly set per cluster or node
    bridge            = "vnet10"
    dns_domain        = "main"
    dns_servers       = ["10.10.10.1"]
    ipv4_gateway      = "10.10.10.1"
    packages          = ["git","net-tools"]
  }

  clusters = {
    dev = merge(local.defaults, {
        nodes = {
        1 = { mac_address = "BC:24:11:17:66:08", ipv4_address = "10.10.10.21/24", vm_id = "10021", proxmox_node_name = "pve1" }
        2 = { mac_address = "BC:24:11:8C:04:B2", ipv4_address = "10.10.10.22/24", vm_id = "10022", proxmox_node_name = "pve2" }
        3 = { mac_address = "BC:24:11:30:EE:20", ipv4_address = "10.10.10.23/24", vm_id = "10023", proxmox_node_name = "pve3" }
        4 = { mac_address = null, ipv4_address = "10.10.10.24/24", vm_id = "10024", proxmox_node_name = "mother" }
        }
      }
    )
  }

}
