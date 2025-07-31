## Variable to store the ssh private key
variable "ssh_private_key" {
  sensitive = true
}

## Variable to the k3s token
variable "k3s_token" {
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

  connection {
    type        = "ssh"
    user        = "root"
    private_key = var.ssh_private_key
    host        = self.ipv4_address
  }

  # Upload your NixOS configuration files
  provisioner "file" {
    source      = "nixos"
    destination = "/mnt/nixos"
  }

  provisioner "file" {
    content     = <<-EOF
      #!/bin/bash
      set -euxo pipefail

      # Export the token early
      export K3S_TOKEN='${var.k3s_token}'

      # Fail early if not set
      if [ -z "$K3S_TOKEN" ]; then
        echo "K3S_TOKEN missing"
        exit 1
      fi

      # Install Nix non-interactively
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates

      # Install Nix
      curl -L https://nixos.org/nix/install | bash -s -- --daemon

      # Source the profile (bash is used so 'source' works)
      # shellcheck source=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

      # Preserve token for downstream tools
      export K3S_TOKEN

      # Run the disko and install
      nix run github:nix-community/disko -- --mode disko /mnt/nixos/disko.nix
      nixos-install --flake /mnt/nixos#prod-master --no-root-password
    EOF
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "/bin/bash -e /tmp/bootstrap.sh"
    ]
  }

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