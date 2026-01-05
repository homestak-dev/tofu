# Config-loader module
# Loads and merges configuration from site-config YAML files
#
# Merge order (later values override earlier):
#   1. site.yaml (site-wide defaults)
#   2. nodes/{node}.yaml (PVE instance config)
#   3. envs/{env}.yaml (environment config)
#   4. secrets.yaml (sensitive values, resolved by reference)

locals {
  # Load YAML files
  site_config = yamldecode(file("${var.site_config_path}/site.yaml"))
  env_config  = yamldecode(file("${var.site_config_path}/envs/${var.env}.yaml"))
  secrets     = yamldecode(file("${var.site_config_path}/secrets.yaml"))

  # Determine which node to use (var.node override or env's node reference)
  # Envs are node-agnostic templates - node is specified at deploy time via -var="node=..."
  # Fallback to env's node field for backward compatibility
  node_name   = coalesce(var.node, try(local.env_config.node, null))
  node_config = yamldecode(file("${var.site_config_path}/nodes/${local.node_name}.yaml"))

  # Site defaults (from site.yaml)
  defaults = try(local.site_config.defaults, {})

  # Resolve API token from secrets (node.api_token is a key into secrets.api_tokens)
  api_token_key = local.node_config.api_token
  api_token     = local.secrets.api_tokens[local.api_token_key]

  # Resolve root password from secrets
  root_password = local.secrets.passwords.vm_root

  # Resolve SSH keys from secrets (list of key names -> list of public keys)
  # Default to all keys if not specified
  ssh_key_names = try(local.env_config.ssh_keys, try(local.node_config.ssh_keys, keys(local.secrets.ssh_keys)))
  ssh_keys      = [for name in local.ssh_key_names : local.secrets.ssh_keys[name]]

  # Merged configuration with precedence: env > node > defaults
  merged = {
    # Identity (derived from filenames, not file content)
    env  = var.env
    node = local.node_name

    # API configuration (from node)
    api_endpoint = local.node_config.api_endpoint
    api_token    = local.api_token

    # Node properties
    host         = try(local.node_config.host, null)
    parent_node  = try(local.node_config.parent_node, null)

    # Datastore: env > node > defaults
    datastore = try(
      local.env_config.datastore,
      local.node_config.datastore,
      local.defaults.datastore,
      "local-zfs"
    )

    # SSH user: env > node > defaults
    ssh_user = try(
      local.env_config.ssh_user,
      local.node_config.ssh_user,
      local.defaults.ssh_user,
      "root"
    )

    # Domain: env > node > defaults
    domain = try(
      local.env_config.domain,
      local.node_config.domain,
      local.defaults.domain,
      "local"
    )

    # Timezone: env > node > defaults
    timezone = try(
      local.env_config.timezone,
      local.node_config.timezone,
      local.defaults.timezone,
      "UTC"
    )

    # Node IP (from env)
    node_ip = try(local.env_config.node_ip, null)

    # Secrets
    root_password = local.root_password
    ssh_keys      = local.ssh_keys
  }
}

# Validate that a node was specified
# Required when env file is node-agnostic (no node: field)
check "node_required" {
  assert {
    condition     = local.node_name != null
    error_message = "Node must be specified via -var=\"node=<name>\" when env file has no node: field"
  }
}
