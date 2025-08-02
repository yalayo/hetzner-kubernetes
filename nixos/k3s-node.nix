{ config, pkgs, lib, ... }:

let
  # read token if you wrote it to /etc/k3s-token (populated via environment or file injection)
  k3sToken = if builtins.pathExists /etc/k3s-token
  then builtins.readFile /etc/k3s-token
  else "";

in
{
  system.stateVersion = "24.11";

  services.openssh.enable = true;
  #users.users.root.openssh.authorizedKeys.keys = [
  #  "ssh-ed25519 AAAA...your-public-key-here..." # replace or supply via module override
  #];

  environment.systemPackages = with pkgs; [ vim ];

  boot.kernelModules = [
    "br_netfilter"
    "overlay"
    "nf_conntrack"
    "ip_tables"
    "ip6_tables"
    "xt_conntrack"
    "xt_mark"
  ];

  networking.sysctl."net.bridge.bridge-nf-call-iptables" = 1;
  networking.sysctl."net.bridge.bridge-nf-call-ip6tables" = 1;
  networking.sysctl."net.ipv4.ip_forward" = 1;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 6443 80 443 ];

  services.k3s.enable = true;
  services.k3s.extraArgs = lib.mkForce (builtins.filter (arg: arg != "") [
    (if k3sToken != "" then "--token=${k3sToken}" else "")
    "--disable=traefik"
  ]);

  services.k3s.kubeconfigEnable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "UTC";
  services.timesyncd.enable = true;

  networking.hostName = "k3s-node";
}