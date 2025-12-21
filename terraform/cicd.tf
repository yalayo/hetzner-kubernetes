## CICD server
/* resource "hcloud_server" "cicd" {
  name        = "cicd"
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
    ip = "10.1.1.100"
  }

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}

output "cicd_ip" {
  value = hcloud_server.cicd.ipv4_address
  description = "Ip of the cicd server"
} */