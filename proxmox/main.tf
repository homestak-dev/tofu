terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  node_name   = "pve1"
  name        = var.vmconf.name
  tags        = var.vmconf.tags
  operating_system {
    type = "l26"
  }
  cpu {
    cores = 2
    type = "host"
  }
  memory {
    dedicated = 2048
  }
  disk {
    datastore_id = "local-zfs"
    file_id      = "local:iso/noble-server-cloudimg-amd64.img"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 40
    file_format  = "raw"
  }
  network_device {
    bridge = "vmbr0"
    vlan_id = var.vmconf.vlan_id
  }
  initialization {
    dns {
      servers = var.vmconf.dns_server
      domain = var.vmconf.dns_domain
    }
    ip_config {
      ipv4 {
        address = var.vmconf.ipv4_address
        gateway = var.vmconf.ipv4_gateway
      }
    }
    datastore_id = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.ubuntu_cloud_init.id
  }
  keyboard_layout = "no"
  agent {
    enabled = true
  }
  startup {
    order      = "3"
    up_delay   = "20"
    down_delay = "20"
  }
  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}

