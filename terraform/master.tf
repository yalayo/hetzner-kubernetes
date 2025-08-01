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

  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: false
    packages: [git curl ca-certificates jq xfsprogs parted]

    write_files:
      - path: /root/fetch_nixos.sh
        permissions: '0755'
        content: |
          #!/bin/bash
          set -euxo pipefail

          # Clone your nixos flake (adjust URL as needed)
          rm -rf /tmp/nixos
          git clone --depth=1 https://github.com/yourorg/nixos.git /tmp/nixos

      - path: /root/bootstrap.sh
        permissions: '0755'
        content: |
          #!/bin/bash
          set -euxo pipefail

          export HOME=/root
          export K3S_TOKEN='${var.k3s_token}'

          # Install Nix (daemon) non-interactively
          curl -L https://nixos.org/nix/install | bash -s -- --daemon

          # Enable flakes
          mkdir -p /etc/nix
          cat <<NIXCONF > /etc/nix/nix.conf
          experimental-features = nix-command flakes
          NIXCONF

          # Source nix profile (bash)
          # shellcheck source=/dev/null
          source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

          # Run disko to partition & format /dev/sda based on your flake spec
          nix run github:nix-community/disko -- --mode disko /tmp/nixos/disko.nix

          # Install NixOS from the flake; adjust the selector if needed
          nixos-install --flake /tmp/nixos#prod-master --no-root-password

          # Reboot into the newly installed system
          reboot

    runcmd:
      - /bin/bash /root/fetch_nixos.sh
      - /bin/bash /root/bootstrap.sh
  EOF

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}