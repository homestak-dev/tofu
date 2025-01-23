variable "vmconf" {
  description = "required parameters to create a virtual machine."
  type = object({
    name          = string
    tags          = list(string)
    vlan_id       = string
    ipv4_address  = string
    ipv4_gateway  = string
    dns_server    = list(string)
    dns_domain    = string
  })
}
