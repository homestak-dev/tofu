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
└── envs/
    ├── common/       # Shared logic (node inheritance/merging)
    ├── dev/          # Development environment (SDN + router)
    ├── k8s/          # Kubernetes environment (SDN + router)
    ├── pve-deb/      # Debian 13 VM for E2E testing (inner PVE)
    └── test/         # Test VM (works on any PVE via tfvars)
```

## Related Projects

```
/root/homestak/
├── ansible/          # Ansible playbooks for PVE configuration
├── packer/           # Custom cloud images with pre-installed packages
├── scripts/          # E2E test helpers
├── test-runs/        # Generated test reports
└── tofu/             # This project - VM provisioning
```

- **ansible**: Playbooks for configuring Proxmox hosts and installing PVE on Debian 13. The `pve-deb` environment provisions VMs for E2E testing.
- **packer**: Builds custom Debian cloud images with qemu-guest-agent pre-installed. Boot time: ~16s vs ~35s with stock images.

## Key Technologies

- **OpenTofu** - IaC provisioning
- **bpg/proxmox provider v0.90.0** - Proxmox VE integration
- **Cloud-Init** - VM initialization
- **local-zfs** - Storage backend
- **Debian Cloud Images** - VM base (Bookworm 12, Trixie 13)
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
| `proxmox-file` | Cloud image management (local or URL source) |
| `proxmox-sdn` | VXLAN zone, vnet, and subnet configuration |
| `envs/common` | Configuration inheritance logic |
| `envs/{dev,k8s,test}` | Environment-specific cluster definitions |

### Cloud Image Sources

The `proxmox-file` module supports two modes via `source_type`:

**Local (default)** - Uses pre-built packer images (~16s boot):
```hcl
module "cloud_image" {
  source        = "../../proxmox-file"
  local_file_id = "local:iso/debian-12-custom.img"
}
```

**URL** - Downloads from remote source (~35s boot):
```hcl
module "cloud_image" {
  source          = "../../proxmox-file"
  source_type     = "url"
  source_file_url = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  source_file_path = "debian-12-generic-amd64.img"
}
```

Packer images must be published before using local mode:
```bash
cd /root/homestak/packer && ./publish.sh
```

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

### K8s Environment Network Topology

```
Internet
    │
    ▼
┌─────────┐
│  vmbr0  │  (Proxmox bridge - 10.0.12.0/24)
└────┬────┘
     │
┌────┴────┐
│ router  │  VM 20000 - dual NIC gateway
│ (ens19) │  10.0.12.x (DHCP from vmbr0)
│ (ens18) │  10.10.20.1 (static, runs dnsmasq)
└────┬────┘
     │
┌────┴────┐
│   k8s   │  (SDN VXLAN bridge - 10.10.20.0/24)
└────┬────┘
     │
     ├── sysadm1   VM 20001 - 10.10.20.10 (static)
     ├── kubeadm1  VM 20101 - 10.10.20.101 (static)
     ├── kubeadm2  VM 20102 - 10.10.20.102 (static)
     ├── kubeadm3  VM 20103 - 10.10.20.103 (static)
     ├── k3s-prod1 VM 20201 - 10.10.20.201 (static)
     ├── k3s-prod2 VM 20202 - 10.10.20.202 (static)
     └── k3s-prod3 VM 20203 - 10.10.20.203 (static)
```

## Conventions

- **VM IDs**: 5-digit numeric (10000 router, 10001+ VMs)
- **MAC prefix**: BC:24:11:*
- **Hostnames**: `{cluster}{instance}` (e.g., dev1, dev2)
- **Cloud-init files**: `{hostname}-meta.yaml`, `{hostname}-user.yaml`

## Environment Endpoints

Each environment targets different Proxmox endpoints configured in `terraform.tfvars`:
- Separate API tokens per environment
- Distinct IP ranges:
  - dev: 10.10.10.0/24
  - k8s: 10.10.20.0/24
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

## E2E Testing Environments

### pve-deb (Inner PVE)

Provisions a Debian 13 VM for PVE installation and nested VM testing.

| Property | Value |
|----------|-------|
| VM ID | 99913 |
| Hostname | pve-deb |
| CPU | 2 cores (faster packer builds) |
| Memory | 8192 MB |
| Disk | 64 GB on local-zfs |
| Image | debian-13-custom.img |

**Usage:**
```bash
cd /root/homestak/tofu/envs/pve-deb
tofu apply
```

### test (Parameterized Test VM)

Works on both outer and inner PVE via tfvars. Key variables:

| Variable | Outer PVE | Inner PVE |
|----------|-----------|-----------|
| `proxmox_node_name` | pve | pve-deb |
| `vm_datastore_id` | local-zfs | local |
| `proxmox_api_endpoint` | https://pve:8006 | https://<inner-ip>:8006 |

The `nested-pve` Ansible role auto-generates tfvars for inner PVE usage.

## Provider Documentation

- https://search.opentofu.org/provider/bpg/proxmox/latest
- https://github.com/bpg/terraform-provider-proxmox
