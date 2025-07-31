{ config, pkgs, ... }:

let
  tokenValue = builtins.getEnv "K3S_TOKEN";
in {
  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "main";

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  time.timeZone = "UTC";

  services.openssh.enable = true;

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [ ];
    token = if tokenValue == "" then throw "K3S_TOKEN is not set" else tokenValue;
    clusterInit = true;
  };

  environment.systemPackages = with pkgs; [
    git
    curl
  ];
}