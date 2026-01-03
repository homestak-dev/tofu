locals {
  default_settings = {
    proxmox_node_name = "pve1"
    bridge            = "vmbr0"
    packages          = []
    mac_address       = null
    ipv4_address      = "dhcp"
    ipv4_gateway      = "10.10.10.1"
    dns_domain        = "local"
    dns_servers       = []
  }

  # the nodes data structure "flattens" the sparse cluster_data (defined
  # in each of the environment-specific locals.tf file) and provides an 
  # inheritance mechanism for defining values at the default, cluster,
  # and node levels. credit/blame goes to ChatGPT.

  nodes = {
    for node in flatten([
      for cluster_name, cluster_data in var.clusters : [
        for i in range(length(keys(cluster_data.nodes)) > 0 ? length(keys(cluster_data.nodes)) : 1) : merge(
          local.default_settings, cluster_data, try(cluster_data.nodes[i + 1], {}),
          {
            cluster_name      = cluster_name
            instance_num      = length(keys(cluster_data.nodes)) > 0 ? i + 1 : ""
            hostname          = try(cluster_data.nodes[i + 1].hostname, "${cluster_name}${length(keys(cluster_data.nodes)) > 0 ? i + 1 : ""}")
            proxmox_node_name = try(cluster_data.nodes[i + 1].proxmox_node_name, cluster_data.proxmox_node_name, local.default_settings.proxmox_node_name)
            vm_id             = try(cluster_data.nodes[i + 1].vm_id, null)
            mac_address       = try(cluster_data.nodes[i + 1].mac_address, cluster_data.mac_address, local.default_settings.mac_address)
            ipv4_address      = try(cluster_data.nodes[i + 1].ipv4_address, cluster_data.ipv4_address, local.default_settings.ipv4_address)
            ipv4_gateway      = try(cluster_data.nodes[i + 1].ipv4_gateway, cluster_data.ipv4_gateway, local.default_settings.ipv4_gateway)
            dns_domain        = try(cluster_data.nodes[i + 1].dns_domain, cluster_data.dns_domain, local.default_settings.dns_domain)
            dns_servers       = try(cluster_data.nodes[i + 1].dns_servers, cluster_data.dns_servers, local.default_settings.dns_servers)
          }
        )
      ]
    ])
    : node.hostname => node
  }
}
