terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_download_file.md
resource "proxmox_virtual_environment_download_file" "cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  url          = var.source_file_url
  overwrite    = false
}

# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/resources/virtual_environment_file.md
resource "proxmox_virtual_environment_file" "cloud_init_meta" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  source_raw {
    data = <<-EOF
      #cloud-config
      local-hostname: "${var.vm_hostname}"
      timezone: "America/Denver"
      packages:
        - qemu-guest-agent

      EOF
    file_name  = "meta-data.${var.vm_hostname}.yaml"
  }
}

# Snippets are not enabled by default in new Proxmox installations.
resource "proxmox_virtual_environment_file" "cloud_init_user" {
  content_type = "snippets"
  datastore_id = "local"
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
    type = "host"
  }
  disk {
    datastore_id = "local-zfs"
    discard      = "on"
    file_format  = "raw"
    file_id      = proxmox_virtual_environment_download_file.cloud_image.id
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
    ignore_changes = [ ]
  }
  memory {
    dedicated = 2048
    floating  = 2048
  }
  name        = var.vm_name
  network_device {
    bridge  = "vmbr0"
    vlan_id = var.vm_vlan_id
  }
  node_name   = var.proxmox_node_name
  operating_system {
    type = "l26"
  }
  startup {
    order      = "3"
    up_delay   = "10"
    down_delay = "10"
  }
  tags        = var.vm_tags
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

