terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

locals {
  router_user_data = <<-EOF
    #cloud-config
    hostname: router
    fqdn: router.homestak

    users:
      - name: root
        lock_passwd: false
        hashed_passwd: $6$rounds=500000$uCCa0piztTDbgiIJ$8ekZqACZr9iACDdbW5eCgIQVHOETlTTu/RkIBf.7nsHfJgop30M8c/tAXbzqz.cJfGxF8cLiXYzGKeu65ZUCg.
        ssh_authorized_keys:
          - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqZRMXskxuD1sVvspZ3Ut97vcGbQxmfDGnZu3AOjgK2VBdQZAzc9R0pvrhZiS26rM4pg54yNdyzgV9dgxRB9FUzgkW87GcjG3EcODo9vFqhsDp3628JiIQXw78vISMZtVcArGhVgjA9qfw3YnZscdOp735HeG2RyglhumPDkFgs6g3FhqQ+e+W8t0LT3+CyWtSMQwy3VSQi+VhUfueLuuxSjbi9FDEpse550ZldwKJjgloaXfs95MWjV4gs7xVnHlNnSNUvbxKntmRWoM8c3jD8zOsgQHFNDtHRT7xIt7OteIhhg2tRPdDFXfihnt/2ij9kwttD/UGhTDe7wCSrln1uaQZsUjeSlMyihQ7dvjlz8IqZNHMz8XaaPFroxIsTyh4A9njhym28BJ7VMlwsM8VwloPBKPf/MoQ6VyejXHyQ9ScqHkiOlXEUX/CPxOUL1Q0voeZGyYw4tLErGuG/GdeyIl1S8nRh7F/eR2uj9zYmhAYx3MtLzqAm0K2DT+9v6n2kWg3biJQXLUxL2rTEeBIF5jgX0+CWRDrZ6MIwXws3/9AdkxPR6QIubWWIPbpBI0m4/vB7R9+2C7Xge1cZFIxCedpx4IY5Y9x2vsqeMM56Iw8IGyt9Sm1yN0cdrtCThnKA0SCVUzbTsqjF8ifzN+yOdbtZxRtHR8msdLx6rk/tQ== root@pve"
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
  vm_started        = true
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

  vm_ipv4_address = each.value.ipv4_address
  vm_ipv4_gateway = each.value.ipv4_address == "dhcp" ? null : module.sdn.gateway
  vm_dns_domain   = each.value.dns_domain
  vm_dns_servers  = each.value.dns_servers

  depends_on = [module.sdn, module.router]
}
