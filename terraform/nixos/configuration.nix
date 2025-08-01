{ config, pkgs, lib, ... }:

let
  tokenValue = builtins.getEnv "K3S_TOKEN";
in {
  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "main";

  networking.firewall.allowedTCPPorts = [
    6443 # k3s API
    2379 # etcd client (HA embedded etcd)
    2380 # etcd peer (HA embedded etcd)
  ];
  networking.firewall.enable = true;
  networking.firewall.allowedUDPPorts = [
    8472 # flannel overlay (multi-node)
  ];

  time.timeZone = "UTC";

  services.openssh.enable = true;

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [ ];
    token = lib.mkForce (if tokenValue == "" then throw "K3S_TOKEN is not set" else tokenValue);
    clusterInit = true;
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    cloud-utils  # provides growpart
  ];

  # Resize the root partition/filesystem if the underlying volume was expanded.
  systemd.services.resize-root = {
    description = "Grow root partition and filesystem (if needed)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -e
      marker=/etc/resize-root-done

      if [ -f "$marker" ]; then
        exit 0
      fi

      # Attempt to grow partition 1 on /dev/sda (common root disk layout on Hetzner)
      if command -v growpart >/dev/null 2>&1; then
        # ignore errors if nothing to do
        growpart /dev/sda 1 || true

        # Detect filesystem on /dev/sda1 and grow it
        fstype=$(lsblk -no FSTYPE /dev/sda1)
        case "$fstype" in
          ext4)
            resize2fs /dev/sda1 || true
            ;;
          xfs)
            # xfs_growfs grows mounted fs; assume it's mounted at /
            xfs_growfs / || true
            ;;
          *)
            echo "Unknown or unsupported filesystem for automatic grow: $fstype"
            ;;
        esac
      fi

      touch "$marker"
    '';
  };

  # Optional: if the partition table was changed manually during provisioning and
  # you absolutely need the new table, you can force a one-time reboot by creating
  # a flag in the provisioning script instead of doing it here.
}