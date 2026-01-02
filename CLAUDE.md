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
├── envs/
│   ├── common/       # Shared logic (node inheritance/merging)
│   ├── dev/          # Development environment
│   └── prod/         # Production environment
├── cluster/          # Multi-VM cluster orchestration
└── test/             # Single test VM
```

## Key Technologies

- **OpenTofu** - IaC provisioning
- **bpg/proxmox provider v0.70.0** - Proxmox VE integration
- **Cloud-Init** - VM initialization
- **Ceph** - Storage backend (cephpool1)
- **Ubuntu Cloud Images** - VM base (Noble/24.04)

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
| `envs/common` | Configuration inheritance logic |
| `envs/{dev,prod}` | Environment-specific cluster definitions |
| `cluster` | Multi-cluster orchestration |

## Conventions

- **VM IDs**: 5-digit numeric (10001-10024 dev, 10101-10103 prod)
- **MAC prefix**: BC:24:11:*
- **Hostnames**: `{cluster}{instance}` (e.g., kubeadm1, dev2)
- **Cloud-init files**: hostname-specific (meta-data.{hostname}.yaml)

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

## Provider Documentation

- https://search.opentofu.org/provider/bpg/proxmox/latest
- https://github.com/bpg/terraform-provider-proxmox
