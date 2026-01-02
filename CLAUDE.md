# Tofu - Proxmox VM Provisioning with OpenTofu

Infrastructure-as-Code project for provisioning virtual machines on Proxmox VE using OpenTofu (Terraform-compatible).

## Quick Reference

```bash
# Common commands (run from environment directory)
tofu init      # Initialize providers/modules
tofu plan      # Preview changes
tofu apply     # Apply changes
tofu destroy   # Tear down (use with caution)
tofu fmt       # Format HCL files
```

## Project Structure

```
tofu/
├── proxmox-vm/       # Reusable module: single VM provisioning
├── proxmox-file/     # Reusable module: cloud image management
├── proxmox-sdn/      # Reusable module: VXLAN SDN networking
├── envs/
│   ├── common/       # Shared logic (node inheritance/merging)
│   ├── dev/          # Development environment
│   └── prod/         # Production environment
├── cluster/          # Multi-VM cluster orchestration
└── test/             # Single test VM
```

## Key Technologies

- **OpenTofu** - IaC provisioning
- **bpg/proxmox provider v0.90.0** - Proxmox VE integration
- **Cloud-Init** - VM initialization
- **local-zfs** - Storage backend
- **Debian 12 Cloud Images** - VM base (Bookworm)
- **VXLAN SDN** - Software-defined networking for VM isolation

## Architecture

### 3-Level Configuration Inheritance

Node configuration flows through a merge hierarchy in `envs/common/locals.tf`:

1. **Defaults** (`local.default_settings`) - base values for all VMs
2. **Cluster** (`local.clusters`) - per-cluster overrides (bridge, DNS, packages)
3. **Node** - individual VM specifics (hostname, IP, MAC, VM ID)

### Module Responsibilities

| Module | Purpose |
|--------|---------|
| `proxmox-vm` | Atomic VM resource (CPU, memory, disk, network, cloud-init) |
| `proxmox-file` | Download and manage cloud images on Proxmox |
| `proxmox-sdn` | VXLAN zone, vnet, and subnet configuration |
| `envs/common` | Configuration inheritance logic |
| `envs/{dev,prod}` | Environment-specific cluster definitions |
| `cluster` | Multi-cluster orchestration |

### Dev Environment Network Topology

```
Internet
    │
    ▼
┌─────────┐
│  vmbr0  │  (Proxmox bridge - 10.0.12.0/24)
└────┬────┘
     │
┌────┴────┐
│ router  │  VM 10000 - dual NIC gateway
│ (ens19) │  10.0.12.x (DHCP from vmbr0)
│ (ens18) │  10.10.10.1 (static, runs dnsmasq)
└────┬────┘
     │
┌────┴────┐
│ vnet10  │  (SDN VXLAN bridge - 10.10.10.0/24)
└────┬────┘
     │
┌────┴────┐
│  dev1   │  VM 10001 - 10.10.10.x (DHCP from router)
└─────────┘
```

## Conventions

- **VM IDs**: 5-digit numeric (10000 router, 10001+ VMs)
- **MAC prefix**: BC:24:11:*
- **Hostnames**: `{cluster}{instance}` (e.g., dev1, dev2)
- **Cloud-init files**: `{hostname}-meta.yaml`, `{hostname}-user.yaml`

## Environment Endpoints

Each environment targets different Proxmox endpoints configured in `terraform.tfvars`:
- Separate API tokens per environment
- Distinct IP ranges (10.10.10.0/24 subnets)
- Environment-specific storage and network bridges

## Prerequisites

- OpenTofu CLI installed
- SSH key at `~/.ssh/id_rsa`
- Proxmox API access (endpoint + token in terraform.tfvars)
- Network connectivity to Proxmox API

## Known Issues

### Debian 12 Cloud-Init First-Boot Kernel Panic

Debian 12 cloud images can kernel panic on first boot when disk is expanded. Fix: add `serial_device {}` to VM resource config.

```hcl
resource "proxmox_virtual_environment_vm" "example" {
  # ... other config ...
  serial_device {}  # Prevents first-boot kernel panic
}
```

Reference: https://forum.proxmox.com/threads/160125/

## Provider Documentation

- https://search.opentofu.org/provider/bpg/proxmox/latest
- https://github.com/bpg/terraform-provider-proxmox
