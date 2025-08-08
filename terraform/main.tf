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

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}" 
}

variable "hcloud_token" {
  sensitive = true
}

variable "firewall_source_ip" {
  default = "0.0.0.0"
}

locals {
  internal_cidr = hcloud_network.network.ip_range
}

## Open ports
resource "hcloud_firewall" "cluster" { 
  name = "cluster-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22" 
    source_ips = [
      "${var.firewall_source_ip}/0" 
    ]
  }

  # Kubernetes API server only reachable from inside the internal network
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [local.internal_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "2379-2380"
    source_ips = ["10.1.1.0/16"]
  }
}

## Networking
resource "hcloud_network" "network" {
  name     = "cluster-network"
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