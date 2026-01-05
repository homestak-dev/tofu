# Changelog

## v0.5.0-rc1 - 2026-01-04

Consolidated pre-release with config-loader module.

### Highlights

- config-loader module for YAML configuration
- Loads from site-config/nodes/*.yaml and envs/*.yaml
- Resolves secrets by key reference

### Changes

- Documentation improvements
- Cross-repo consistency updates

## v0.3.0 - 2026-01-04

### Features

- Add `config-loader` module for YAML configuration
  - Loads from `site-config/nodes/*.yaml` and `site-config/envs/*.yaml`
  - Resolves secret references from `site-config/secrets.yaml`
  - Merge order: site.yaml → nodes/{node}.yaml → envs/{env}.yaml → secrets.yaml
- All environments now use config-loader instead of tfvars

### Changes

- **BREAKING**: Remove tfvars support in favor of YAML configuration

## v0.2.0 - 2026-01-04

### Features

- Add configurable `ssh_user` for Proxmox provider (supports non-root SSH)
- Bump bpg/proxmox provider to 0.91.0

### Changes

- **BREAKING**: Move secrets to [site-config](https://github.com/homestak-dev/site-config) repository
- Environment tfvars now in `site-config/envs/*/terraform.tfvars`
- Remove in-repo SOPS encryption (Makefile, .githooks, .sops.yaml, *.tfvars.enc)

## v0.1.0-rc1 - 2026-01-03

### Modules

- **proxmox-vm**: VM provisioning with cloud-init
- **proxmox-file**: Cloud image management (local or URL source)
- **proxmox-sdn**: VXLAN SDN networking

### Environments

- **dev**: Development environment with SDN isolation
- **k8s**: Kubernetes environment with SDN isolation
- **pve-deb**: Inner PVE VM for E2E testing
- **test**: Parameterized test VM (works on any PVE host)

### Infrastructure

- 3-level configuration inheritance (defaults, cluster, node)
- Branch protection enabled (PR reviews for non-admins)
- Dependabot for provider updates
- Tested via iac-driver nested-pve-roundtrip scenario
