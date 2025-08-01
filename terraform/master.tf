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
    content = <<-EOT
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

      # Install Nix (needed to run disko)
      curl -L https://nixos.org/nix/install | bash -s -- --no-daemon
      # Source nix profile so `nix` is in PATH
      . /home/root/.nix-profile/etc/profile.d/nix.sh  # adjust if installing as root; install script drops profile in /root/.nix-profile if root

      # Run disko to set up the target disk and mount at /mnt/nixos
      # Assumes you uploaded a disko.nix into /mnt/nixos/disko.nix that describes the desired layout.
      nix run github:nix-community/disko -- --mode disko /mnt/nixos/disko.nix

      # At this point /mnt/nixos should be the mounted target root
      # Ensure mount points for chroot
      mkdir -p /mnt/nixos/{proc,sys,dev,run,etc}

      # Prepare chroot environment: bind-mount pseudo-filesystems
      for fs in proc sys dev run; do
        mount --bind "/$fs" "/mnt/nixos/$fs"
      done

      # Ensure DNS works inside chroot
      cp /etc/resolv.conf /mnt/nixos/etc/resolv.conf

      chroot /mnt/nixos /usr/bin/env K3S_TOKEN="$K3S_TOKEN" /bin/bash -eux <<'CHROOT'
        curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
        . /root/.nix-profile/etc/profile.d/nix.sh

        mkdir -p /etc/nix
        cat <<NIXCONF > /etc/nix/nix.conf
        experimental-features = nix-command flakes
        NIXCONF

        nixos-install --flake /#prod-master --no-root-password
      CHROOT

      # Cleanup: unmount the binds (best-effort)
      for fs in run dev sys proc; do
        umount -l "/mnt/nixos/$fs" || true
      done

      reboot
    EOT
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