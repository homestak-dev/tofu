terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

module "cloud_image" {
  source = "../proxmox-file"
}

locals {
  clusters = {
    demo = {                # cluster name (e.g., mgmt, prod, etc.)
      count     = 0         # number of instances; set >= 1 to enable, 0 to disable
      bridge    = "vmbr0"
      hostname  = "tofutest"
      packages  = [ ]
    },
    sysadm = {
      count     = 1
      bridge    = "mgmt"
      hostname  = "sysadm"
      packages  = ["curl","git"]
    },
    kubeadm = {
      count     = 3
      bridge    = "mgmt"
      hostname  = "kubeadm"
      packages  = ["git"]
    },
    kube-prod = {
      count     = 3
      bridge    = "prod"
      hostname  = "k3s-prod"
      packages  = [ ]
    },
    dev = {
      count     = 1
      bridge    = "dev"
      hostname  = "dev"
      packages  = ["git"]
    }
  }

  nodes = flatten([
    for cluster_name, cluster_data in local.clusters : [
      for i in range(cluster_data.count) : {
        cluster_name  = cluster_name
        instance_num  = cluster_data.count > 1 ? i + 1 : ""
        bridge        = cluster_data.bridge
        hostname      = cluster_data.hostname
        packages      = cluster_data.packages
      }
    ]
  ])
}

module "nodes_constructor" {
  source = "../proxmox-vm"

  for_each = {
    for instance in local.nodes : 
    "${instance.cluster_name}${instance.instance_num}" => instance
  }

  cloud_image_id  = module.cloud_image.file_id
  vm_bridge       = each.value.bridge
  vm_hostname     = "${each.value.hostname}${each.value.instance_num}"
  vm_name         = "${each.value.hostname}${each.value.instance_num}"
  vm_packages     = each.value.packages
}