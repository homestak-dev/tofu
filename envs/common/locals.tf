  # the nodes data structure "flattens" the sparse cluster_data (defined
  # in each of the environment-specific locals.tf file) and provides an 
  # inheritance mechanism for defining values at the default, cluster,
  # and node levels.

locals {
  default_settings = {
    proxmox_node_name = "pve1"
    bridge            = "vmbr0"
    packages          = []
    mac_address       = "00:00:00:00:00:00"
    ipv4_address      = "dhcp"
    ipv4_gateway      = "10.10.10.1"
    dns_domain        = "local"
    dns_servers       = ["8.8.8.8", "1.1.1.1"]
  }

  nodes = {
    for node in flatten([
      for cluster_name, cluster_data in var.clusters : [
        for i in range(length(keys(cluster_data.nodes)) > 0 ? length(keys(cluster_data.nodes)) : 1) : merge(
          local.default_settings, cluster_data, lookup(cluster_data.nodes, i + 1, {}),
          {
            cluster_name      = cluster_name
            instance_num      = length(keys(cluster_data.nodes)) > 0 ? i + 1 : ""
            hostname          = "${cluster_name}${length(keys(cluster_data.nodes)) > 0 ? i + 1 : ""}"
            proxmox_node_name = try(lookup(cluster_data.nodes, i + 1, {}).proxmox_node_name, lookup(cluster_data, "proxmox_node_name", local.default_settings.proxmox_node_name))
            vm_id             = try(lookup(cluster_data.nodes, i + 1, {}).vm_id, null)
            mac_address       = try(lookup(cluster_data.nodes, i + 1, {}).mac_address, lookup(cluster_data, "mac_address", local.default_settings.mac_address))
            ipv4_address      = try(lookup(cluster_data.nodes, i + 1, {}).ipv4_address, lookup(cluster_data, "ipv4_address", local.default_settings.ipv4_address))
            ipv4_gateway      = try(lookup(cluster_data.nodes, i + 1, {}).ipv4_gateway, lookup(cluster_data, "ipv4_gateway", local.default_settings.ipv4_gateway))
            dns_domain        = try(lookup(cluster_data.nodes, i + 1, {}).dns_domain, lookup(cluster_data, "dns_domain", local.default_settings.dns_domain))
            dns_servers       = try(lookup(cluster_data.nodes, i + 1, {}).dns_servers, lookup(cluster_data, "dns_servers", local.default_settings.dns_servers))
          }
        )
      ]
    ])
    : node.hostname => node
  }
}
