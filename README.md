# tofu

OpenTofu modules for Proxmox VM provisioning with cloud-init.

## Overview

Infrastructure-as-Code project for provisioning virtual machines on Proxmox VE using OpenTofu (Terraform-compatible).

Part of the [homestak-dev](https://github.com/homestak-dev) organization.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/homestak-dev/tofu.git
cd tofu
make setup      # Configure git hooks
make decrypt    # Decrypt secrets (requires age key)

# Deploy an environment
cd envs/dev
tofu init
tofu plan
tofu apply
```

## Secrets Management

Credentials are encrypted with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age).

```bash
make setup    # Configure git hooks, check dependencies
make decrypt  # Decrypt terraform.tfvars in all envs
make encrypt  # Re-encrypt after changes
make check    # Verify setup
```

**First-time setup:** You need an age key at `~/.config/sops/age/keys.txt`.

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
    ├── pve-deb/      # E2E testing (inner PVE)
    └── test/         # Parameterized test VM
```

## Prerequisites

- OpenTofu CLI
- age + sops for secrets
- SSH key at `~/.ssh/id_rsa`
- Proxmox API access

## Documentation

See [CLAUDE.md](CLAUDE.md) for detailed architecture, network topology, and conventions.

## Related Repos

| Repo | Purpose |
|------|---------|
| [ansible](https://github.com/homestak-dev/ansible) | Proxmox host configuration |
| [iac-driver](https://github.com/homestak-dev/iac-driver) | E2E test orchestration |
| [packer](https://github.com/homestak-dev/packer) | Custom Debian cloud images |

## License

Apache 2.0 - see [LICENSE](LICENSE)
