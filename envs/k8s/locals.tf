locals {
  # Defaults for k8s environment
  defaults = {
    proxmox_node_name = module.config.node
    bridge            = "k8s"
    dns_domain        = "k8s.local"
    dns_servers       = ["10.10.20.1"]
    ipv4_gateway      = "10.10.20.1"
    packages          = []
  }

  # Node template - all fields required for type consistency
  node_defaults = {
    vm_id             = null
    mac_address       = null
    ipv4_address      = "dhcp"
    proxmox_node_name = module.config.node
  }

  clusters = {
    # Management/sysadmin node
    sysadm = merge(local.defaults, {
      packages = ["curl", "git"]
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 20001, ipv4_address = "10.10.20.10/24" })
      }
    })

    # Kubernetes cluster via kubeadm (3 nodes)
    kubeadm = merge(local.defaults, {
      packages = ["git"]
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 20101, ipv4_address = "10.10.20.101/24" })
        2 = merge(local.node_defaults, { vm_id = 20102, ipv4_address = "10.10.20.102/24" })
        3 = merge(local.node_defaults, { vm_id = 20103, ipv4_address = "10.10.20.103/24" })
      }
    })

    # Production k3s cluster (3 nodes)
    k3s-prod = merge(local.defaults, {
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 20201, ipv4_address = "10.10.20.201/24" })
        2 = merge(local.node_defaults, { vm_id = 20202, ipv4_address = "10.10.20.202/24" })
        3 = merge(local.node_defaults, { vm_id = 20203, ipv4_address = "10.10.20.203/24" })
      }
    })
  }
}
