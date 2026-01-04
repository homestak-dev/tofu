# Load configuration from site-config
module "config" {
  source = "../../modules/config-loader"

  site_config_path = var.site_config_path
  env              = "k8s"
  node             = var.node  # Optional override
}
