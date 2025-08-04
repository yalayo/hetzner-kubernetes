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
  name        = "prod-node-${count.index+1}"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  server_type = "cax11" 
  keep_disk   = true
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id] 
  firewall_ids = [hcloud_firewall.cluster.id]

  public_net {
    ipv4_enabled = true
    #ipv6_enabled = false
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
  value = hcloud_server.node.*.ipv4_address
  description = "List of public IPv4 addresses of the three nodes"
}

output "first_node_ip" {
  value = element(hcloud_server.node.*.ipv4_address, 0)
  description = "Bootstrap (first) node, used for --cluster-init"
}

output "first_node_internal_ip" {
  value       = hcloud_server.node[0].network[0].ip
  description = "Internal IP of the bootstrap node"
}