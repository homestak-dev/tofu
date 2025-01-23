resource "proxmox_virtual_environment_file" "ubuntu_cloud_init" {

  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve1"

  source_raw {
    data = <<EOF
#cloud-config
timezone: "America/Denver"

packages:
  - qemu-guest-agent

runcmd:
  - apt update
  - apt upgrade -y
#  - apt-get install -y qemu-guest-agent
#  - systemctl enable ssh
  - reboot now

users:
  - name: jderose
    groups: sudo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${trimspace("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCUIcnWQJ1PN6uaFB67HD17rKQSY4w2g2JRTD6/1LaJhXxSZe9n50yf4/hek+xlCdnGpWxRrS3PTaLFFMB150h+qt2MjwceWRfXb4MAB6RDxFwoY+Gw9VRZ/SfzTCieADVUBdUUcY2pX6GGnCE5+HM6x2NF3w0vHA5RyMt41n+XW34vmrZUPtGiHnAb4VI7LaWj1ROPmf1UVEggFiEDqm7RMG4da2QoJucND22HDugHYT3J45ZC16F6XsAYX9sYKFoFDFvE3apSztrRejz9ON0tGJSVMDZ2NvcJezpTCpBRKtKP4SJpfwWx3U3CXnGc17mvaJEHiJv+opr4RVSQXlYjDkv1VhpC60gZOsXKVmt0IMs8ZSEIDXsJQXaAXI62A6rTqW4dDPOxsQOHeG/OlYUjbNsZUvFESPSE0YhaAUM779lNsUpxaVOQIa1aiwBW6asQux4cN4aicpIlia8Em7Sg6K3kSAZwCosdIfZwyq7kmp2RDlqkgW6VM7NCWSjavgM= jderose@studio")}
    sudo: ALL=(ALL) NOPASSWD:ALL
EOF
    file_name = "ubuntu.cloud-config.yaml"
  }
}

