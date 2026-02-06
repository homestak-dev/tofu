# Environment: generic
# Primary execution environment for iac-driver workflows.
#
# Receives pre-resolved configuration via tfvars.json from ConfigResolver.
# No direct site-config access - all values passed as variables.
#
# Usage: tofu apply -var-file=/path/to/tfvars.json

locals {
  # Convert vms list to map keyed by name
  vms_map = { for vm in var.vms : vm.name => vm }

  # Generate cloud-init user-data for each VM
  user_data = { for name, vm in local.vms_map : name => <<-EOF
    #cloud-config
    hostname: ${name}

    users:
      - name: ${var.automation_user}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          ${indent(6, join("\n", formatlist("- \"%s\"", var.ssh_keys)))}
      - name: root
        lock_passwd: false
        hashed_passwd: ${var.root_password}

    package_update: ${length(vm.packages) > 0 ? "true" : "false"}
    packages:
      - qemu-guest-agent
      ${indent(4, join("\n", formatlist("- %s", vm.packages)))}
%{if var.spec_server != ""}

    write_files:
      - path: /etc/profile.d/homestak.sh
        permissions: '0644'
        content: |
          # Homestak spec discovery environment variables (v0.45+)
          export HOMESTAK_SPEC_SERVER=${var.spec_server}
          export HOMESTAK_IDENTITY=${name}
%{if vm.auth_token != ""}
          export HOMESTAK_AUTH_TOKEN=${vm.auth_token}
%{endif}
%{endif}

    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
%{if var.spec_server != ""}
      - |
        # Fetch spec and apply config on first boot (v0.45+)
        if [ ! -f /usr/local/etc/homestak/state/spec.yaml ]; then
          mkdir -p /usr/local/etc/homestak/state
          . /etc/profile.d/homestak.sh
          /usr/local/bin/homestak spec get --insecure 2>/dev/null || true
        fi
        if [ ! -f /usr/local/etc/homestak/state/config-complete.json ]; then
          /usr/local/lib/homestak/iac-driver/run.sh config 2>/dev/null || true
        fi
%{endif}
  EOF
  }
}

module "vm" {
  source   = "../../proxmox-vm"
  for_each = local.vms_map

  proxmox_node_name = var.node
  vm_id             = each.value.vmid
  vm_name           = each.key
  vm_datastore_id   = var.datastore

  cloud_image_id = var.images[each.value.image]

  vm_cpu_cores = each.value.cores
  vm_memory    = each.value.memory
  vm_disk_size = each.value.disk

  network_devices = [{ bridge = each.value.bridge }]

  cloud_init_user_data = local.user_data[each.key]

  vm_ipv4_address = each.value.ip
  vm_ipv4_gateway = each.value.ip == "dhcp" ? null : each.value.gateway
}
