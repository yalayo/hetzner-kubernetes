## Variable to store the ssh private key
variable "ssh_private_key" {
  sensitive = true
}

## Variable to the k3s token
variable "k3s_token" {
  sensitive = true
}

## VM
resource "hcloud_server" "node" { 
  count       = 3
  name        = "prod-node-${count.index}"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  server_type = "cax11" 
  keep_disk   = true
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id] 
  firewall_ids = [hcloud_firewall.cluster.id]

  public_net {
    ipv4_enabled = true
  }

  network {
    network_id = hcloud_network.network.id
    ip = "10.1.1.${count.index+1}"
  }

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

output "nodes_ips" {
  value = [for s in hcloud_server.node : s.ipv4_address]
  description = "List of public IPv4 addresses of the three nodes"
}

output "first_node_ip" {
  value       = hcloud_server.node[0].ipv4_address
  description = "Bootstrap (first) node, used for --cluster-init"
}