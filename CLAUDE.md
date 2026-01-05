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

# Deploy to a specific node (required - envs are node-agnostic templates)
tofu apply -var="node=pve"
tofu apply -var="node=father"

# With custom site-config path (development)
tofu plan -var="node=pve" -var="site_config_path=/path/to/site-config"
```

## Project Structure

```
tofu/
├── modules/
│   └── config-loader/    # YAML config loading from site-config
├── proxmox-vm/           # Reusable module: single VM provisioning
├── proxmox-file/         # Reusable module: cloud image management
├── proxmox-sdn/          # Reusable module: VXLAN SDN networking
└── envs/
    ├── common/           # Shared logic (node inheritance/merging)
    ├── dev/              # Development environment (SDN + router)
    ├── k8s/              # Kubernetes environment (SDN + router)
    ├── pve-deb/          # Debian 13 VM for E2E testing (inner PVE)
    └── test/             # Test VM (works on any PVE)
```

## Related Projects

Part of the [homestak-dev](https://github.com/homestak-dev) organization:

| Repo | Purpose |
|------|---------|
| [bootstrap](https://github.com/homestak-dev/bootstrap) | Entry point - curl\|bash setup |
| [site-config](https://github.com/homestak-dev/site-config) | Site-specific secrets and configuration |
| [ansible](https://github.com/homestak-dev/ansible) | Proxmox host configuration, PVE installation |
| [iac-driver](https://github.com/homestak-dev/iac-driver) | Orchestration engine |
| [packer](https://github.com/homestak-dev/packer) | Custom Debian cloud images |
| [tofu](https://github.com/homestak-dev/tofu) | This project - VM provisioning |

## Configuration Loading

Configuration is loaded from site-config YAML files via the `config-loader` module:

```
site-config/
├── site.yaml           # Site-wide defaults (timezone, domain, datastore)
├── secrets.yaml        # All sensitive values (SOPS encrypted)
├── nodes/              # PVE instance configuration (primary key from filename)
│   └── {node}.yaml     # API endpoint, token ref, datastore
└── envs/               # Deployment topology templates (node-agnostic)
    └── {env}.yaml      # env-specific settings, node at deploy time
```

### Config-Loader Module

Each environment uses the config-loader module to load configuration:

```hcl
# envs/{env}/config.tf
module "config" {
  source = "../../modules/config-loader"

  site_config_path = var.site_config_path  # Default: /opt/homestak/site-config
  env              = "dev"                  # Environment name (from filename)
  node             = var.node               # Target PVE node (required)
}

# Use outputs in providers and resources
provider "proxmox" {
  endpoint  = module.config.api_endpoint
  api_token = module.config.api_token
}

# Available outputs:
# - module.config.api_endpoint  (Proxmox API URL)
# - module.config.api_token     (Proxmox API token, sensitive)
# - module.config.node          (PVE node name)
# - module.config.datastore     (Default storage)
# - module.config.ssh_user      (SSH user for provider)
# - module.config.domain        (DNS domain)
# - module.config.root_password (VM root password hash, sensitive)
# - module.config.ssh_keys      (List of SSH public keys, sensitive)
```

### Merge Order

Configuration is merged with later values overriding earlier:

1. `site.yaml` - Site-wide defaults
2. `nodes/{node}.yaml` - PVE instance configuration
3. `envs/{env}.yaml` - Environment-specific settings
4. `secrets.yaml` - Sensitive values (resolved by reference)

### Secret References

Node and env files reference secrets by key name:

```yaml
# nodes/pve.yaml
api_token: pve  # -> secrets.api_tokens.pve
```

The config-loader resolves these at runtime from the decrypted `secrets.yaml`.

**Setup:**
```bash
cd ../site-config
make setup    # Configure git hooks, check dependencies
make decrypt  # Decrypt secrets (requires age key at ~/.config/sops/age/keys.txt)
```

## Key Technologies

- **OpenTofu** - IaC provisioning
- **bpg/proxmox provider v0.91.0** - Proxmox VE integration
- **Cloud-Init** - VM initialization
- **local-zfs** - Storage backend
- **Debian Cloud Images** - VM base (Bookworm 12, Trixie 13)
- **VXLAN SDN** - Software-defined networking for VM isolation

## Architecture

### Configuration Inheritance

Node configuration flows through a merge hierarchy in `envs/common/locals.tf`:

1. **Defaults** (`local.default_settings`) - base values for all VMs
2. **Cluster** (`local.clusters`) - per-cluster overrides (bridge, DNS, packages)
3. **Node** - individual VM specifics (hostname, IP, MAC, VM ID)

### Module Responsibilities

| Module | Purpose |
|--------|---------|
| `modules/config-loader` | Load and merge YAML config from site-config |
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
cd ../packer && ./publish.sh
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

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `site_config_path` | /opt/homestak/site-config | Path to site-config directory |
| `node` | (required) | Target PVE node - envs are node-agnostic templates |

## Prerequisites

- OpenTofu CLI installed
- site-config repository set up and decrypted (see [site-config](https://github.com/homestak-dev/site-config))
- SSH key at `~/.ssh/id_rsa`
- Proxmox API access (endpoint + token in site-config)
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

| Environment | Purpose |
|-------------|---------|
| `pve-deb` | Inner PVE VM (Debian 13 + Proxmox VE, 2 cores, 8GB, 64GB) |
| `test` | Parameterized test VM (works on outer or inner PVE) |

See `../iac-driver/CLAUDE.md` for full E2E procedure and architecture.

## Provider Documentation

- https://search.opentofu.org/provider/bpg/proxmox/latest
- https://github.com/bpg/terraform-provider-proxmox
