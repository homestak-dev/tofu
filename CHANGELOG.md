# Changelog

## Unreleased

- Bump bpg/proxmox provider to 0.91.0

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
