locals {

  defaults = {
    proxmox_node_name = null              # explicitly set per cluster or node
    bridge            = "main"
    dns_domain        = "main"
    dns_servers       = ["10.10.10.10"]
    ipv4_gateway      = "10.10.10.1"
    packages          = ["git"]
  }

  clusters = {
    kubeadm = merge(local.defaults, {
        nodes = {
          1 = { mac_address = "BC:24:11:D6:6B:90", ipv4_address = "10.10.10.101/24", vm_id = 10101, proxmox_node_name = "pve1" }
          2 = { mac_address = "BC:24:11:A7:98:F3", ipv4_address = "10.10.10.102/24", vm_id = 10102, proxmox_node_name = "pve2" }
          3 = { mac_address = "BC:24:11:A4:D2:25", ipv4_address = "10.10.10.103/24", vm_id = 10103, proxmox_node_name = "pve3" }
        }
      }
    )
  }

}
