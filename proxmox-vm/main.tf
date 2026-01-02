terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# Cloud-init user-data
resource "proxmox_virtual_environment_file" "cloud_init_user" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  overwrite    = true

  source_raw {
    data      = var.cloud_init_user_data
    file_name = "${var.vm_name}.user.yaml"
  }
}

# Cloud-init network-data (only created if custom network config provided)
resource "proxmox_virtual_environment_file" "cloud_init_network" {
  count        = var.cloud_init_network_data != null ? 1 : 0
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  overwrite    = true

  source_raw {
    data      = var.cloud_init_network_data
    file_name = "${var.vm_name}.network.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = var.proxmox_node_name
  vm_id     = var.vm_id
  tags      = var.vm_tags
  on_boot   = var.vm_on_boot
  started   = var.vm_started

  agent {
    enabled = true
  }

  cpu {
    type = "host"
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = var.cloud_image_id
    file_format  = "raw"
    interface    = "virtio0"
    size         = var.vm_disk_size
    discard      = "on"
    iothread     = true
  }

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
    }
  }

  # Use custom network-data file if provided, otherwise use Proxmox ip_config
  initialization {
    datastore_id         = "local-zfs"
    user_data_file_id    = proxmox_virtual_environment_file.cloud_init_user.id
    network_data_file_id = var.cloud_init_network_data != null ? proxmox_virtual_environment_file.cloud_init_network[0].id : null

    dynamic "dns" {
      for_each = var.cloud_init_network_data == null ? [1] : []
      content {
        domain  = var.vm_dns_domain
        servers = var.vm_dns_servers
      }
    }

    dynamic "ip_config" {
      for_each = var.cloud_init_network_data == null ? [1] : []
      content {
        ipv4 {
          address = var.vm_ipv4_address
          gateway = var.vm_ipv4_gateway
        }
      }
    }
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  startup {
    order      = var.vm_startup_order
    up_delay   = 10
    down_delay = 10
  }

  stop_on_destroy = true

  lifecycle {
    ignore_changes = [tags]
  }
}
