terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

locals {
  # Base cloud-init template - generates per-VM config with hostname
  vm_user_data = { for k, v in module.common.nodes : k => <<-EOF
    #cloud-config
    hostname: ${v.hostname}
    fqdn: ${v.hostname}.${v.dns_domain}

    users:
EOF
  }

  # Shared user/package config (appended to each VM's cloud-init)
  base_user_data_suffix = <<-EOF
      - name: root
        lock_passwd: false
        hashed_passwd: ${var.root_password_hash}
        ssh_authorized_keys:
          ${indent(6, join("\n", formatlist("- \"%s\"", module.common.root_ssh_keys)))}
      - name: jderose
        groups: sudo
        shell: /bin/bash
        ssh_authorized_keys:
          ${indent(6, join("\n", formatlist("- \"%s\"", module.common.jderose_ssh_keys)))}
        sudo: ALL=(ALL) NOPASSWD:ALL

    package_update: true
    packages:
      - qemu-guest-agent

    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
EOF

  # Combined per-VM cloud-init (hostname + base config)
  base_user_data = { for k, v in local.vm_user_data : k => "${v}${local.base_user_data_suffix}" }

  # Router-specific cloud-init
  router_user_data = <<-EOF
    #cloud-config
    hostname: router
    fqdn: router.homestak

    users:
      - name: root
        lock_passwd: false
        hashed_passwd: ${var.root_password_hash}
        ssh_authorized_keys:
          ${indent(6, join("\n", formatlist("- \"%s\"", module.common.root_ssh_keys)))}
      - name: jderose
        groups: sudo
        shell: /bin/bash
        ssh_authorized_keys:
          ${indent(6, join("\n", formatlist("- \"%s\"", module.common.jderose_ssh_keys)))}
        sudo: ALL=(ALL) NOPASSWD:ALL

    package_update: true
    packages:
      - qemu-guest-agent
      - dnsmasq
      - iptables-persistent

    write_files:
      - path: /etc/sysctl.d/99-ip-forward.conf
        content: |
          net.ipv4.ip_forward=1
      - path: /etc/dnsmasq.d/homestak.conf
        content: |
          interface=ens18
          bind-interfaces
          dhcp-range=10.10.10.100,10.10.10.200,12h
          dhcp-option=option:router,10.10.10.1
          dhcp-option=option:dns-server,10.10.10.1
          dhcp-option=option:domain-name,homestak
          server=10.0.12.1

    runcmd:
      - sysctl -p /etc/sysctl.d/99-ip-forward.conf
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - systemctl enable dnsmasq
      - systemctl restart dnsmasq
      - iptables -t nat -A POSTROUTING -o ens19 -j MASQUERADE
      - iptables -A FORWARD -i ens18 -o ens19 -j ACCEPT
      - iptables -A FORWARD -i ens19 -o ens18 -m state --state RELATED,ESTABLISHED -j ACCEPT
      - netfilter-persistent save
  EOF

  router_network_data = <<-EOF
    version: 2
    ethernets:
      ens18:
        addresses:
          - 10.10.10.1/24
      ens19:
        dhcp4: true
  EOF
}

# SDN - VXLAN overlay network for VM isolation
module "sdn" {
  source         = "../../proxmox-sdn"
  zone_id        = "homestak"
  vnet_id        = "vnet10"
  peers          = ["10.0.12.124"]
  subnet_cidr    = "10.10.10.0/24"
  subnet_gateway = "10.10.10.1"
}

module "common" {
  source   = "../common"
  clusters = local.clusters
}

module "cloud_image" {
  source            = "../../proxmox-file"
  proxmox_node_name = var.proxmox_node_name
  source_file_url   = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  source_file_path  = "debian-12-generic-amd64.img"
}

# Router VM - provides DHCP and NAT for SDN
module "router" {
  source = "../../proxmox-vm"

  cloud_image_id    = module.cloud_image.file_id
  proxmox_node_name = var.proxmox_node_name
  vm_id             = 10000
  vm_name           = "router"
  vm_started        = false  # Started by boot_sequence below
  vm_startup_order  = 1

  network_devices = [
    { bridge = module.sdn.vnet_id },  # ens18 - Internal SDN
    { bridge = "vmbr0" }               # ens19 - External
  ]

  cloud_init_user_data    = local.router_user_data
  cloud_init_network_data = local.router_network_data

  depends_on = [module.sdn]
}

# Dev VMs
module "vm" {
  source   = "../../proxmox-vm"
  for_each = module.common.nodes

  cloud_image_id    = module.cloud_image.file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id             = each.value.vm_id
  vm_name           = each.value.hostname

  network_devices = [{ bridge = module.sdn.vnet_id }]

  cloud_init_user_data = local.base_user_data[each.key]

  vm_ipv4_address = each.value.ipv4_address
  vm_ipv4_gateway = each.value.ipv4_address == "dhcp" ? null : module.sdn.gateway
  vm_dns_domain   = each.value.dns_domain
  vm_dns_servers  = each.value.dns_servers

  depends_on = [module.sdn]  # No router dependency - parallel provisioning
}

# Boot VMs in sequence after parallel provisioning
resource "null_resource" "boot_sequence" {
  # Re-run if any VM is recreated
  triggers = {
    router_id = module.router.vm_id
    vm_ids    = join(",", [for k, v in module.vm : v.vm_id])
  }

  # Start router first, wait for it, then start other VMs
  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting router..."
      qm start 10000
      echo "Waiting for router to be ready..."
      sleep 30
      echo "Starting dev VMs..."
      %{for k, v in module.vm~}
      qm start ${v.vm_id}
      %{endfor~}
    EOT
  }

  depends_on = [module.router, module.vm]
}
