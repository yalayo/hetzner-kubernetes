## Variable to store the ssh private key
variable "ssh_private_key" {
  sensitive = true
}

## VM
resource "hcloud_server" "master" { 
  name        = "prod-master"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  server_type = "cax21" 
  keep_disk   = true
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id] 
  firewall_ids = [hcloud_firewall.cluster.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get -y install ca-certificates curl
    sudo sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
  EOF

  public_net {
    ipv6_enabled = true
    ipv4_enabled = true
  }

  network {
    network_id = hcloud_network.network.id
    ip         = "10.1.1.1"
    alias_ips  = [
      "10.1.1.2"
    ]
  }

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

variable "nixos_system" {
  type        = string
  description = "Path to the built NixOS system closure"
}

variable "nixos_disko" {
  type        = string
  description = "Path to the built disko script"
}

module "install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = var.nixos_system
  nixos_partitioner = var.nixos_disko
  target_host       = hcloud_server.master.ipv4_address
  build_on_remote   = true
  ssh_private_key   = var.ssh_private_key

  depends_on = [
    hcloud_server.master
  ]
}