variable "source_type" {
  description = "Image source: 'url' (download) or 'local' (pre-staged)"
  type        = string
  default     = "local"
}

variable "local_file_id" {
  description = "Proxmox file ID for local image (when source_type = 'local')"
  type        = string
  default     = null
}

variable "proxmox_node_name" {
  description = "Proxmox Node Name; e.g.: pve1"
  default     = "pve"
  type        = string
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
  default = null
  type = string
}

variable "source_file_checksum_algo" {
  description = "checksum algorithm for cloud image file; e.g.: md5, sha256, sha512"
  default = null
  type = string
}
