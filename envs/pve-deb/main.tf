terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.91.0"
    }
  }
}

# Toggle: set to true to create test VM, false to destroy
locals {
  enabled = true

  # Filter nodes based on enabled flag
  active_nodes = local.enabled ? module.common.nodes : {}

  # Per-VM cloud-init with hostname
  vm_user_data = { for k, v in local.active_nodes : k => <<-EOF
    #cloud-config
    hostname: ${v.hostname}
    fqdn: ${v.hostname}.${v.dns_domain}

    users:
EOF
  }

  base_user_data_suffix = <<-EOF
      - name: root
        lock_passwd: false
        hashed_passwd: ${module.config.root_password}
        ssh_authorized_keys:
          ${indent(6, join("\n", formatlist("- \"%s\"", module.config.ssh_keys)))}

    package_update: true
    packages:
      - qemu-guest-agent

    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
EOF

  base_user_data = { for k, v in local.vm_user_data : k => "${v}${local.base_user_data_suffix}" }
}

module "common" {
  source   = "../common"
  clusters = local.clusters
}

module "cloud_image" {
  count         = local.enabled ? 1 : 0
  source        = "../../proxmox-file"
  local_file_id = "local:iso/debian-13-custom.img"
}

module "vm" {
  source   = "../../proxmox-vm"
  for_each = local.active_nodes

  cloud_image_id    = module.cloud_image[0].file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id             = each.value.vm_id
  vm_name           = each.value.hostname

  # Larger specs for PVE install
  vm_cpu_cores = 2
  vm_memory    = 8192
  vm_disk_size = 64

  network_devices = [{ bridge = each.value.bridge }]

  cloud_init_user_data = local.base_user_data[each.key]

  vm_ipv4_address = each.value.ipv4_address
  vm_ipv4_gateway = each.value.ipv4_address == "dhcp" ? null : each.value.ipv4_gateway
  vm_dns_domain   = each.value.dns_domain
  vm_dns_servers  = each.value.dns_servers
}
