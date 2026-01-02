terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_file.md
resource "proxmox_virtual_environment_file" "cloud_init_meta" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  source_raw {
    data = <<-EOF
      instance-id: ${var.vm_hostname}
      local-hostname: ${var.vm_hostname}
      EOF
    file_name = "${var.vm_hostname}-meta.yaml"
  }
}

# Snippets are not enabled by default in new Proxmox installations.
resource "proxmox_virtual_environment_file" "cloud_init_user" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  source_file {
    path       = "${path.module}/user-data.yaml"
    file_name  = "${var.vm_hostname}-user.yaml"
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_vm.md
resource "proxmox_virtual_environment_vm" "this" {
  agent {
    enabled = true
  }
  cpu {
    type = "host"
  }
  disk {
    datastore_id = "local-zfs"
    discard      = "on"
    file_format  = "raw"
    file_id      = var.cloud_image_id
    interface    = "virtio0"
    iothread     = true
    size         = 10
  }
  initialization {
    datastore_id = "local-zfs"
    dns {
      domain  = var.vm_dns_domain
      servers = var.vm_dns_servers
    }
    ip_config {
      ipv4 {
        address = var.vm_ipv4_address
        gateway = var.vm_ipv4_gateway
      }
    }
    meta_data_file_id = proxmox_virtual_environment_file.cloud_init_meta.id
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user.id
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  memory {
    dedicated = 4096
  }
  name = var.vm_name
  network_device {
    bridge      = var.vm_bridge
    mac_address = var.vm_mac_address
    vlan_id     = var.vm_vlan_id
  }
  node_name = var.proxmox_node_name
  operating_system {
    type = "l26"
  }
  serial_device {}
  reboot  = false
  started = false
  startup {
    order      = "3"
    up_delay   = "10"
    down_delay = "10"
  }
  stop_on_destroy = true
  tags  = var.vm_tags
  vm_id = var.vm_id
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
