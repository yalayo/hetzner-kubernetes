terraform {
  cloud {
    organization = "rondon-sarnik"

    workspaces {
      name = "prod-kubernetes"
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

variable "firewall_source_ip" {
  default = "0.0.0.0"
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}" 
}

## Open ports
resource "hcloud_firewall" "common-firewall" { 
  name = "common-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22" 
    source_ips = [
      "${var.firewall_source_ip}/0" 
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80" 
    source_ips = [
      "${var.firewall_source_ip}/0" 
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443" 
    source_ips = [
      "${var.firewall_source_ip}/0" 
    ]
  }
}

## Networking
resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.1.0.0/16"
}

resource "hcloud_network_subnet" "network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = "eu-central"
  ip_range     = "10.1.1.0/24"
}

## SSH Key 
data "hcloud_ssh_key" "ssh_key" {
  name = "ssh-key-1"
}

## VM 97aNREFMkaqPhuXcEq4C
resource "hcloud_server" "master" { 
  name        = "prod-master"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  server_type = "cax21" 
  keep_disk   = true
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id] 
  firewall_ids = [hcloud_firewall.common-firewall.id]

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
    ip         = "10.0.1.1"
    alias_ips  = [
      "10.0.1.2",
      "10.0.1.3"
    ]
  }

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

output "master_public_ip4" {
  value = "${hcloud_server.master.ipv4_address}"
}