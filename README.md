# tofu

OpenTofu modules for Proxmox VM provisioning with cloud-init.

## Overview

Infrastructure-as-Code project for provisioning virtual machines on Proxmox VE using OpenTofu (Terraform-compatible).

Part of the [homestak-dev](https://github.com/homestak-dev) organization.

## Quick Start

```bash
# Clone tofu and site-config
git clone https://github.com/homestak-dev/tofu.git
git clone https://github.com/homestak-dev/site-config.git

# Setup secrets
cd site-config
make setup && make decrypt

# Deploy an environment
cd ../tofu/envs/dev
tofu init
tofu plan
tofu apply
```

## Secrets Management

Credentials are managed in the [site-config](https://github.com/homestak-dev/site-config) repository using SOPS + age.

See [site-config README](https://github.com/homestak-dev/site-config#readme) for setup instructions.

## Project Structure

```
tofu/
├── proxmox-vm/       # Reusable module: VM provisioning
├── proxmox-file/     # Reusable module: cloud image management
├── proxmox-sdn/      # Reusable module: VXLAN SDN networking
└── envs/
    ├── common/       # Shared configuration logic
    ├── dev/          # Development environment
    ├── k8s/          # Kubernetes environment
    ├── nested-pve/   # Debian 13 VM for PVE installation
    └── test/         # Parameterized test VM
```

## Prerequisites

- OpenTofu CLI
- [site-config](https://github.com/homestak-dev/site-config) set up and decrypted
- SSH key at `~/.ssh/id_rsa`
- Proxmox API access

## Documentation

See [CLAUDE.md](CLAUDE.md) for detailed architecture, network topology, and conventions.

## Related Repos

| Repo | Purpose |
|------|---------|
| [bootstrap](https://github.com/homestak-dev/bootstrap) | Entry point - curl\|bash setup |
| [site-config](https://github.com/homestak-dev/site-config) | Site-specific secrets and configuration |
| [ansible](https://github.com/homestak-dev/ansible) | Proxmox host configuration |
| [iac-driver](https://github.com/homestak-dev/iac-driver) | Orchestration engine |
| [packer](https://github.com/homestak-dev/packer) | Custom Debian cloud images |

## License

Apache 2.0 - see [LICENSE](LICENSE)
