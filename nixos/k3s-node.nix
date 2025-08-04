{ config, pkgs, lib, ... }:

let
  fileToken = if builtins.pathExists /etc/k3s-token
    then builtins.readFile /etc/k3s-token
    else "";
  effectiveToken = lib.mkForce (if config.k3s.token != "" then config.k3s.token else fileToken);

  # Custom extra args: clusterInit (bool), serverURL (string, optional), tlsSAN (optional)
  clusterInit = config.k3s.clusterInit or false;
  joinServer = config.k3s.joinServer or "";
  tlsSan = config.k3s.tlsSan or "";
in {
  options.k3s = {
    token = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Shared k3s cluster token";
    };
    clusterInit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run with --cluster-init (first server)";
    };
    joinServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Existing server to join, e.g. https://ip:6443";
    };
  };

  config = {
    system.stateVersion = "24.11";

    services.openssh.enable = true;

    environment.systemPackages = with pkgs; [ vim jq ];

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

    # k3s service with dynamic flags
    services.k3s = {
      enable = true;
      role = "server";
      token = effectiveToken;
      extraFlags = lib.mkForce (builtins.concatStringsSep " " (builtins.filter (s: s != "") [
        (if clusterInit then "--cluster-init" else "")
        (if joinServer != "" then "--server ${joinServer}" else "")
      ]));
    };

    # Boot loader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Time
    time.timeZone = "UTC";
    services.timesyncd.enable = true;

    # Hostname
    networking.hostName = "cluster-node";
  }
}