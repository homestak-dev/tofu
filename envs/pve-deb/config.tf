# Load configuration from site-config
module "config" {
  source = "../../modules/config-loader"

  site_config_path = var.site_config_path
  env              = "pve-deb"
  node             = var.node  # Optional override
}
