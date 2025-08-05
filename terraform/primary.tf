## Primary node
resource "hcloud_server" "main" {
  name        = "prod-main"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  server_type = "cx22" 
  keep_disk   = true
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id] 
  firewall_ids = [hcloud_firewall.cluster.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.network.id
    ip = "10.1.1.1"
  }

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

output "first_node_ip" {
  value = hcloud_server.main.ipv4_address
  description = "Bootstrap (first) node, used for --cluster-init"
}

output "first_node_internal_ip" {
  value = "10.1.1.1"
  description = "Internal IP of the bootstrap node"
}