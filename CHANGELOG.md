# Changelog

## v0.13 - 2026-01-10

- Release alignment with homestak-dev v0.13

## v0.12 - 2025-01-09

- Release alignment with homestak-dev v0.12

## v0.11 - 2026-01-08

- Release alignment with iac-driver v0.11

## v0.10 - 2026-01-08

### Documentation

- Add third-party acknowledgments for bpg/proxmox provider
- Fix CLAUDE.md: add missing `gateway` field in vms variable

### CI/CD

- Add GitHub Actions workflow for `tofu fmt` and `tofu validate`

### Housekeeping

- Enable secret scanning and Dependabot

## v0.9 - 2026-01-07

### Features

- Add `debian-13-pve` to default images map for nested PVE testing

### Housekeeping

- Add `**/data/` to .gitignore (TF_DATA_DIR cache from direct tofu runs)

## v0.8 - 2026-01-07

No changes - version bump for unified release.

## v0.7 - 2026-01-06

### Bug Fixes

- Fix gateway bug in VM provisioning - now correctly passed to cloud-init (closes #20)

### Changes

- Remove `.states/` directory and gitignore entry (moved to iac-driver)
- Update docs: replace deprecated `pve` with real node names
- Code review improvements (closes #17, #18, #19)
- Update Dependabot config for current directory structure

## v0.6 - 2026-01-06

### Phase 5: Generic Environment

- Add `envs/generic/` - receives pre-resolved config from iac-driver
- **Breaking:** Delete `modules/config-loader/` (replaced by iac-driver ConfigResolver)
- **Breaking:** Delete `envs/dev/`, `envs/k8s/`, `envs/nested-pve/`, `envs/test/`
- Keep `envs/common/` and `envs/prod/` (legacy)
- tofu now acts as "dumb executor" - all config logic in iac-driver

## v0.5 - 2026-01-04

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
- **nested-pve**: Debian 13 (Trixie) VM for PVE 9.x installation
- **test**: Parameterized test VM (works on any PVE host)

### Infrastructure

- 3-level configuration inheritance (defaults, cluster, node)
- Branch protection enabled (PR reviews for non-admins)
- Dependabot for provider updates
- Tested via iac-driver nested-pve-roundtrip scenario
