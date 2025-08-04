## Secondary nodes
resource "hcloud_server" "node" { 
  count       = 1
  name        = "prod-node-${count.index+1}"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  server_type = "cax11" 
  keep_disk   = true
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id] 
  firewall_ids = [hcloud_firewall.cluster.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.network.id
    ip = "10.1.1.${count.index+2}"
  }

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

output "nodes_ips" {
  value = hcloud_server.node.*.ipv4_address
  description = "List of public IPv4 addresses of the three nodes"
}