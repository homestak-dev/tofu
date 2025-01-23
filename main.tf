module "k3s-vm" {
  source = "./proxmox"

  vmconf = {
    name          = "mgmt1"
    tags          = ["tofu", "ubuntu", "k3s"]
    vlan_id       = "30"
    ipv4_address  = "10.0.30.101/24"
    ipv4_gateway  = "10.0.30.1"
    dns_server    = ["10.0.30.1"]
    dns_domain    = "kube.jderose.net"
  }
}
