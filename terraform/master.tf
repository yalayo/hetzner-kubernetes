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

      export K3S_TOKEN='${var.k3s_token}'

      if [ -z "$K3S_TOKEN" ]; then
        echo "K3S_TOKEN missing"
        exit 1
      fi

      # Install Nix non-interactively
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates

      # Prepare chroot environment: bind-mount pseudo-filesystems
      for fs in proc sys dev run; do
        mount --bind "/$fs" "/mnt/nixos/$fs"
      done

      # Ensure DNS works inside chroot
      cp /etc/resolv.conf /mnt/nixos/etc/resolv.conf

      # Enter chroot and perform NixOS installation via flake
      chroot /mnt/nixos /usr/bin/env K3S_TOKEN="$K3S_TOKEN" /bin/bash -eux <<'EOF'
      # Install Nix (single-user) so we can use flakes and nixos-install
      curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
      # Load Nix profile
      . /root/.nix-profile/etc/profile.d/nix.sh

      # Enable flakes inside the chroot
      mkdir -p /etc/nix
      cat <<NIXCONF > /etc/nix/nix.conf
      experimental-features = nix-command flakes
      NIXCONF

      # Run installation from flake; adjust the flake name if different
      nixos-install --flake /mnt/nixos#prod-master --no-root-password
      EOF

      # Cleanup: unmount the binds (best-effort)
      for fs in run dev sys proc; do
        umount -l "/mnt/nixos/$fs" || true
      done

      reboot
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