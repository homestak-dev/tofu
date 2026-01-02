locals {
  # Defaults for k8s environment
  defaults = {
    proxmox_node_name = "pve"
    bridge            = "vmbr0"
    dns_domain        = "k8s.local"
    dns_servers       = ["8.8.8.8", "1.1.1.1"]
    packages          = []
  }

  # Node template - all fields required for type consistency
  node_defaults = {
    vm_id             = null
    mac_address       = null
    proxmox_node_name = "pve"
  }

  clusters = {
    # Management/sysadmin node
    sysadm = merge(local.defaults, {
      bridge       = "k8smgmt"
      ipv4_gateway = "10.20.10.1"
      packages     = ["curl", "git"]
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 20001, ipv4_address = "10.20.10.10/24" })
      }
    })

    # Kubernetes cluster via kubeadm (3 nodes)
    kubeadm = merge(local.defaults, {
      bridge       = "k8smgmt"
      ipv4_gateway = "10.20.10.1"
      packages     = ["git"]
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 20101, ipv4_address = "10.20.10.101/24" })
        2 = merge(local.node_defaults, { vm_id = 20102, ipv4_address = "10.20.10.102/24" })
        3 = merge(local.node_defaults, { vm_id = 20103, ipv4_address = "10.20.10.103/24" })
      }
    })

    # Production k3s cluster (3 nodes)
    k3s-prod = merge(local.defaults, {
      bridge       = "k8sprod"
      ipv4_gateway = "10.20.20.1"
      packages     = []
      nodes = {
        1 = merge(local.node_defaults, { vm_id = 20201, ipv4_address = "10.20.20.101/24" })
        2 = merge(local.node_defaults, { vm_id = 20202, ipv4_address = "10.20.20.102/24" })
        3 = merge(local.node_defaults, { vm_id = 20203, ipv4_address = "10.20.20.103/24" })
      }
    })
  }
}
