terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }
  }
}

locals {
  # Default user-data if none provided
  default_user_data = <<-EOF
    #cloud-config
    hostname: ${var.vm_name}
    fqdn: ${var.vm_name}.local

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
          - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCUGU3paDWQDG0DdqP7iBlFPwa9Y6Uu8IuV20eiFVH0htKP9UTlKJaYh6+Ef2d/2f98Bhw+TixC/v9EFWN76Rd+ddqI5ez5lc1pkmp+jxsASQmJYt+kNQEoo7hOj01mNBb0WGsZvJqtbHCHXq5yHI5+H3DpNJ9n/9oJK/MSH5kMKkVTX5ACX2bud6dizTIRd2X5wzmmCLQyl0N/QRoMQVokfE3hP5MIqoaPRiAB6FblWAjwjh4qRTStx8kwR4If2DN/S5pSuKUE6OjCTsoMo0rvZOzGdN/lbPCSx9QaXMUw1lpboDik9NGhOL9mBJ+MY96ZQr2R86LN7q7x1jag4kQ18z5qWh5VQBA0AgYb4fHKoaw5600cW9YbkmnaxnSQjPcP0W8fm19MMTj7WurOhkOdzLd21sW7cVUscfU+nMY8ZX2P/7s1MgLmF8TldEXypX+WfbEmEm0nphtdl6W9ubzmFWmgZIRlIw+Lr0IzaWSVanLOtRpGbPZHqzUooF7Ay8= jderose@pve1"
          - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCUIcnWQJ1PN6uaFB67HD17rKQSY4w2g2JRTD6/1LaJhXxSZe9n50yf4/hek+xlCdnGpWxRrS3PTaLFFMB150h+qt2MjwceWRfXb4MAB6RDxFwoY+Gw9VRZ/SfzTCieADVUBdUUcY2pX6GGnCE5+HM6x2NF3w0vHA5RyMt41n+XW34vmrZUPtGiHnAb4VI7LaWj1ROPmf1UVEggFiEDqm7RMG4da2QoJucND22HDugHYT3J45ZC16F6XsAYX9sYKFoFDFvE3apSztrRejz9ON0tGJSVMDZ2NvcJezpTCpBRKtKP4SJpfwWx3U3CXnGc17mvaJEHiJv+opr4RVSQXlYjDkv1VhpC60gZOsXKVmt0IMs8ZSEIDXsJQXaAXI62A6rTqW4dDPOxsQOHeG/OlYUjbNsZUvFESPSE0YhaAUM779lNsUpxaVOQIa1aiwBW6asQux4cN4aicpIlia8Em7Sg6K3kSAZwCosdIfZwyq7kmp2RDlqkgW6VM7NCWSjavgM= jderose@studio"
        sudo: ALL=(ALL) NOPASSWD:ALL

    package_update: true
    packages:
      - qemu-guest-agent

    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
  EOF

  user_data = var.cloud_init_user_data != null ? var.cloud_init_user_data : local.default_user_data
}

# Cloud-init user-data
resource "proxmox_virtual_environment_file" "cloud_init_user" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  overwrite    = true

  source_raw {
    data      = local.user_data
    file_name = "${var.vm_name}-user.yaml"
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
    file_name = "${var.vm_name}-network.yaml"
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
