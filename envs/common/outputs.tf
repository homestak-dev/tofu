output "nodes" {
  value = { for node in local.nodes : node.hostname => node }
}
