{ config, pkgs, lib, ... }:

let
  # Read token if it exists, otherwise empty string
  k3sToken = if builtins.pathExists /etc/k3s-token
    then builtins.readFile /etc/k3s-token
    else "";
in
{
  system.stateVersion = "24.11";

  # SSH server
  services.openssh.enable = true;
  # Uncomment and replace with your key if needed
  # users.users.root.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA...your-public-key-here..."
  # ];

  # Packages
  environment.systemPackages = with pkgs; [ vim ];

  # Kernel modules
  boot.kernelModules = [
    "br_netfilter"
    "overlay"
    "nf_conntrack"
    "ip_tables"
    "ip6_tables"
    "xt_conntrack"
    "xt_mark"
  ];

  # sysctl settings (networking.sysctl → boot.kernel.sysctl in 24.11)
  boot.kernel.sysctl."net.bridge.bridge-nf-call-iptables" = 1;
  boot.kernel.sysctl."net.bridge.bridge-nf-call-ip6tables" = 1;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 6443 80 443 ];

  # k3s service
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [ ];
    token = lib.mkForce (if tokenValue == "" then throw "K3S_TOKEN is not set" else tokenValue);
    clusterInit = true;
  };

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Time
  time.timeZone = "UTC";
  services.timesyncd.enable = true;

  # Hostname
  networking.hostName = "main-node";
}