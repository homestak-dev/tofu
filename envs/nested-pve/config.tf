# Load configuration from site-config
module "config" {
  source = "../../modules/config-loader"

  site_config_path = var.site_config_path
  env              = "nested-pve"
  node             = var.node  # Optional override
}
