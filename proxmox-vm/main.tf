terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_file.md
resource "proxmox_virtual_environment_file" "cloud_init_meta" {
  content_type = "snippets"
  datastore_id = "cephfs"
  node_name    = var.proxmox_node_name
  source_raw {
    data = <<-EOF
      #cloud-config
      local-hostname: "${var.vm_hostname}"
      timezone: "America/Denver"
      packages:
        - qemu-guest-agent
      ${join("\n", formatlist("  - %s", var.vm_packages))}
      EOF
    file_name = "meta-data.${var.vm_hostname}.yaml"
  }
}

# Snippets are not enabled by default in new Proxmox installations.
resource "proxmox_virtual_environment_file" "cloud_init_user" {
  content_type = "snippets"
  datastore_id = "cephfs"
  node_name    = var.proxmox_node_name
  source_file {
    path       = "${path.module}/user-data.yaml"
    file_name  = "user-data.${var.vm_hostname}.yaml"
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_vm.md
resource "proxmox_virtual_environment_vm" "this" {
  agent {
    enabled = true
  }
  cpu {
    cores = 2
    flags = [ ]
    type  = "x86-64-v2-AES"
  }
  disk {
    datastore_id = "pool1"
    discard      = "on"
    file_format  = "raw"
    file_id      = var.cloud_image_id
    interface    = "virtio0"
    iothread     = true
    size         = 10
  }
  initialization {
    datastore_id = "pool1"
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
    dedicated = 4096  # maximum allocated
    floating  = 2048  # minimum allocated
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
  reboot = true
  startup {
    order      = "3"
    up_delay   = "10"
    down_delay = "10"
  }
  tags  = var.vm_tags
  vm_id = var.vm_id
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
