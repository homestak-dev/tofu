terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

locals {
  # Per-VM cloud-init with hostname
  vm_user_data = { for k, v in module.common.nodes : k => <<-EOF
    #cloud-config
    hostname: ${v.hostname}
    fqdn: ${v.hostname}.${v.dns_domain}

    users:
EOF
  }

  # Shared user/package config
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

    package_update: false
    packages:
      - qemu-guest-agent

    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
EOF

  # Combined per-VM cloud-init
  base_user_data = { for k, v in local.vm_user_data : k => "${v}${local.base_user_data_suffix}" }

  # Router cloud-init - gateway for both k8smgmt and k8sprod networks
  router_user_data = <<-EOF
    #cloud-config
    hostname: k8s-router
    fqdn: k8s-router.k8s.local

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

    package_update: false
    packages:
      - qemu-guest-agent
      - iptables-persistent

    write_files:
      - path: /etc/sysctl.d/99-ip-forward.conf
        content: |
          net.ipv4.ip_forward=1

    runcmd:
      - sysctl -p /etc/sysctl.d/99-ip-forward.conf
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - iptables -t nat -A POSTROUTING -o ens20 -j MASQUERADE
      - iptables -A FORWARD -i ens18 -o ens20 -j ACCEPT
      - iptables -A FORWARD -i ens19 -o ens20 -j ACCEPT
      - iptables -A FORWARD -i ens20 -m state --state RELATED,ESTABLISHED -j ACCEPT
      - netfilter-persistent save
  EOF

  router_network_data = <<-EOF
    version: 2
    ethernets:
      ens18:
        addresses:
          - 10.20.10.1/24
      ens19:
        addresses:
          - 10.20.20.1/24
      ens20:
        dhcp4: true
  EOF
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

# SDN - mgmt network (sysadm, kubeadm clusters)
module "sdn_mgmt" {
  source         = "../../proxmox-sdn"
  zone_id        = "k8smgmt"
  vnet_id        = "k8smgmt"
  peers          = [var.proxmox_node_ip]
  subnet_cidr    = "10.20.10.0/24"
  subnet_gateway = "10.20.10.1"
  vxlan_tag      = 200
}

# SDN - prod network (k3s-prod cluster)
module "sdn_prod" {
  source         = "../../proxmox-sdn"
  zone_id        = "k8sprod"
  vnet_id        = "k8sprod"
  peers          = [var.proxmox_node_ip]
  subnet_cidr    = "10.20.20.0/24"
  subnet_gateway = "10.20.20.1"
  vxlan_tag      = 201
}

# Final SDN applier - ensures config is applied after all SDN resources on destroy
resource "proxmox_virtual_environment_sdn_applier" "this" {
  depends_on = [module.sdn_mgmt, module.sdn_prod]
}

# Router VM - gateway for k8smgmt and k8sprod networks
module "router" {
  source = "../../proxmox-vm"

  cloud_image_id    = module.cloud_image.file_id
  proxmox_node_name = var.proxmox_node_name
  vm_id             = 20000
  vm_name           = "k8s-router"
  vm_started        = true
  vm_startup_order  = 1

  network_devices = [
    { bridge = module.sdn_mgmt.vnet_id },  # ens18 - k8smgmt (10.20.10.1)
    { bridge = module.sdn_prod.vnet_id },  # ens19 - k8sprod (10.20.20.1)
    { bridge = "vmbr0" }                    # ens20 - External
  ]

  cloud_init_user_data    = local.router_user_data
  cloud_init_network_data = local.router_network_data

  depends_on = [module.sdn_mgmt, module.sdn_prod]
}

# K8s VMs
module "vm" {
  source   = "../../proxmox-vm"
  for_each = module.common.nodes

  cloud_image_id    = module.cloud_image.file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id             = each.value.vm_id
  vm_name           = each.value.hostname

  network_devices = [{ bridge = each.value.bridge }]

  cloud_init_user_data = local.base_user_data[each.key]

  vm_ipv4_address = each.value.ipv4_address
  vm_ipv4_gateway = each.value.ipv4_address == "dhcp" ? null : each.value.ipv4_gateway
  vm_dns_domain   = each.value.dns_domain
  vm_dns_servers  = each.value.dns_servers

  depends_on = [module.sdn_mgmt, module.sdn_prod]
}
