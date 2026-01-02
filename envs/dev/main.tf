terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
  }
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
resource "proxmox_virtual_environment_file" "router_cloud_init_user" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
      #cloud-config
      hostname: router
      fqdn: router.homestak

      users:
        - name: root
          lock_passwd: false
          hashed_passwd: $6$rounds=500000$uCCa0piztTDbgiIJ$8ekZqACZr9iACDdbW5eCgIQVHOETlTTu/RkIBf.7nsHfJgop30M8c/tAXbzqz.cJfGxF8cLiXYzGKeu65ZUCg.
        - name: jderose
          groups: sudo
          shell: /bin/bash
          ssh_authorized_keys:
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnvGantA04mFEdsK0QbTP1b8w8GFKUf3lTgfQ7y0U6cOt5iHWi8a6eF3QXregEc425mCum9zmlFV0z8NOBPhvn0keSdmI868lH0gfcUy8tKaP+xKRQ+EARAtmKmshb2VI2nhJy0N+af+vWqMk8ecGC8SmLQrITuN1oR/xH4arWV6r3H9qYh2pt6nNxSGKUw7BydGDQTr2fFDe+c19RgnATIyDl2AAcTrIKuQFjXJ3nTCbJRMZ/d93ldfMmRUdKd1FI5z4rrxr20/yeXDPFQmShKqb1HtoGarcXgK2aZ8OfbzI+AKgrErVtxLJ5xIu5Hch68WNeQzN7wxBJEz1mBVJJBn2ItICdh9gnzgJeWKwSDSkJyMDT3tEhRYyCuYlqn/TTTI8IRgj3PyHTJ3bdQD99E2hMMYOCjWErwh2+CdDVi9FTUKXSljpTcYxKvDjgvSsdmGqWo6I+JFNxhwa44UoV/j44A6Z6wvHrmoNpZbN3YmFn6Br0EvAp7r5bwWt6S8c= jderose"
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
    file_name = "router-user-data.yaml"
  }
}

resource "proxmox_virtual_environment_file" "router_cloud_init_network" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
      version: 2
      ethernets:
        ens18:
          addresses:
            - 10.10.10.1/24
        ens19:
          dhcp4: true
      EOF
    file_name = "router-network-data.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "router" {
  name      = "router"
  node_name = var.proxmox_node_name
  vm_id     = 10000
  started   = true
  on_boot   = true

  agent {
    enabled = false
  }

  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 1024
    floating  = 512
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = module.cloud_image.file_id
    interface    = "virtio0"
    size         = 4
    discard      = "on"
    iothread     = true
  }

  # eth0 - Internal SDN network
  network_device {
    bridge = module.sdn.vnet_id
  }

  # eth1 - External host network
  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id         = "local-zfs"
    user_data_file_id    = proxmox_virtual_environment_file.router_cloud_init_user.id
    network_data_file_id = proxmox_virtual_environment_file.router_cloud_init_network.id
  }

  startup {
    order      = 1
    up_delay   = 5
    down_delay = 5
  }

  operating_system {
    type = "l26"
  }

  depends_on = [module.sdn]
}

module "nodes_constructor" {
  source = "../../proxmox-vm"

  for_each = module.common.nodes

  cloud_image_id    = module.cloud_image.file_id
  proxmox_node_name = each.value.proxmox_node_name
  vm_id             = each.value.vm_id
  vm_bridge         = module.sdn.vnet_id
  vm_hostname       = each.value.hostname
  vm_name           = each.value.hostname
  vm_packages       = each.value.packages
  vm_mac_address    = each.value.mac_address
  vm_ipv4_address   = each.value.ipv4_address
  vm_ipv4_gateway   = module.sdn.gateway
  vm_dns_domain     = each.value.dns_domain
  vm_dns_servers    = each.value.dns_servers

  depends_on = [module.sdn, proxmox_virtual_environment_vm.router]
}
