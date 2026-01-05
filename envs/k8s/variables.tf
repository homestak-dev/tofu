# Configuration variables
# Credentials are loaded from site-config via the config-loader module

variable "site_config_path" {
  description = "Path to site-config directory"
  type        = string
  default     = "/opt/homestak/site-config"
}

variable "node" {
  description = "Optional node override (defaults to env's node reference)"
  type        = string
  default     = null
}
