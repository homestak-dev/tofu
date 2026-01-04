# Config-loader module variables
# Loads configuration from site-config YAML files

variable "site_config_path" {
  description = "Path to site-config directory"
  type        = string
  default     = "/opt/homestak/site-config"
}

variable "env" {
  description = "Environment name (matches envs/{env}.yaml)"
  type        = string
}

variable "node" {
  description = "Optional node override (defaults to env's node reference)"
  type        = string
  default     = null
}
