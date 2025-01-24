variable "proxmox_node_name" {
  description = "Proxmox Node Name; e.g.: pve1"
  default = "pve1"
  type = string
}

variable "source_file_path" {
  description = "local path to cloud image (not .iso)"
  default = "noble-server-cloudimg-amd64.img"
  type = string
}

variable "source_file_url" {
  description = "remote url to cloud image (not .iso)"
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  type = string
}

variable "source_file_checksum_val" {
  description = "checksum value for cloud image file"
  default = "63f5e103195545a429aec2bf38330e28ab9c6d487e66b7c4b0060aa327983628"
  type = string
}

variable "source_file_checksum_algo" {
  description = "checksum algorithm for cloud image file; e.g.: md5, sha256, sha512"
  default = "sha256"
  type = string
}
