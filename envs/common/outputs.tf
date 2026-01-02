output "nodes" {
  value = { for node in local.nodes : node.hostname => node }
}

output "ssh_keys" {
  value = local.ssh_keys
}

output "root_ssh_keys" {
  value = local.root_ssh_keys
}

output "jderose_ssh_keys" {
  value = local.jderose_ssh_keys
}

output "all_ssh_keys" {
  value = local.all_ssh_keys
}
