terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

module "test_vm" {
  source = "./proxmox-vm"
  count  = 1      # set this to 1 to enable, 0 to disable
  # required values
  vm_name         = "TofuTestVM"
  vm_hostname     = "tofutest"
}

module "k3s_mgmt" {
  source = "./proxmox-vm"
  count  = 0      # set this >= 1 to enable, 0 to disable
  # required values
  vm_name         = "mgmt${count.index+1}.kube"
  vm_hostname     = "mgmt${count.index+1}"
  # optional values
  vm_tags         = ["k3s","mgmt","tofu","ubuntu"]
  vm_dns_domain   = "kube.jderose.net"
  vm_dns_servers  = ["10.0.30.1"]
  vm_ipv4_address = "10.0.30.10${count.index+1}/24"
  vm_ipv4_gateway = "10.0.30.1"
  vm_vlan_id      = "30"
}

