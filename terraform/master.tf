## Variable to store the ssh private key
variable "ssh_private_key" {
  sensitive = true
}

## Variable to the k3s token
variable "k3s_token" {
  sensitive = true
}

locals {
  configuration_b64 = base64encode(file("${path.module}/nixos/configuration.nix"))
  disko_b64 = base64encode(file("${path.module}/nixos/disko.nix"))
  flake_b64 = base64encode(file("${path.module}/nixos/flake.nix"))
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
      - path: /root/configuration.nix.b64
        permissions: '0644'
        content: |
          ${local.configuration_b64}

      - path: /root/disko.nix.b64
        permissions: '0644'
        content: |
          ${local.disko_b64}

      - path: /root/flake.nix.b64
        permissions: '0644'
        content: |
          ${local.flake_b64}

      - path: /root/bootstrap.sh
        permissions: '0755'
        content: |
          #!/bin/bash
          set -euxo pipefail

          MARKER_FILE="/root/.disko-needs-reboot"

          if [ ! -f "$MARKER_FILE" ]; then
            # === Stage 1: Partitioning ===
            echo "Stage 1: Running disko to partition disk..."

            # Run disko to write partition table
            nix run github:nix-community/disko -- --mode disko /tmp/nixos/disko.nix

            # Notify kernel of partition changes
            partprobe /dev/sda || true

            # Check if kernel has adopted new partition table
            if ! lsblk -no PARTLABEL /dev/sda1 >/dev/null 2>&1; then
              echo "Kernel not using new partition table yet. Scheduling reboot..."
              touch "$MARKER_FILE"
              reboot
              exit 0
            fi

            echo "Partition table updated and recognized by kernel."

            # Fall through if kernel already sees partitions (rare without reboot)
          fi

          # === Stage 2: Format partitions and install NixOS ===
          echo "Stage 2: Formatting partitions and installing NixOS..."

          # Format partitions
          mkfs.vfat -F 32 /dev/disk/by-partlabel/disk-main-boot
          mkfs.ext4 /dev/disk/by-partlabel/disk-main-root

          # Mount partitions for install
          mount /dev/disk/by-partlabel/disk-main-root /mnt
          mkdir -p /mnt/boot
          mount /dev/disk/by-partlabel/disk-main-boot /mnt/boot

          export HOME=/root
          export K3S_TOKEN='${var.k3s_token}'

          # Reconstruct nix files
          mkdir -p /tmp/nixos
          base64 -d /root/configuration.nix.b64 > /tmp/nixos/configuration.nix
          base64 -d /root/disko.nix.b64 > /tmp/nixos/disko.nix
          base64 -d /root/flake.nix.b64 > /tmp/nixos/flake.nix

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

          # Install NixOS from the flake; adjust the selector if needed
          nixos-install --flake /tmp/nixos#prod-master --no-root-password

          # Clean up
          umount /mnt/boot
          umount /mnt

          # Remove reboot marker
          rm -f "$MARKER_FILE"

          # Reboot into the newly installed system
          reboot

    runcmd:
      - /bin/bash /root/bootstrap.sh
  EOF

  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
}