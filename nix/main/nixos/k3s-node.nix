{ config, pkgs, lib, ... }:

let
  # Try reading K3S_TOKEN from the evaluation environment; fall back to empty string if unset.
  envToken = let t = builtins.tryEval (builtins.getEnv "K3S_TOKEN"); in if t.success then t.value else "";
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
    tlsSan = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional TLS SAN for k3s";
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
    services.k3s = let
      effectiveToken = lib.mkForce (if config.k3s.token != "" then config.k3s.token else envToken);
    in {
      enable = true;
      role = "server";
      token = effectiveToken;
      clusterInit = true;
      extraFlags = [
        "--tls-san=10.1.1.1"
        "--disable=traefik"
      ];
    };

    # Boot loader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Time
    time.timeZone = "UTC";
    services.timesyncd.enable = true;

    # Hostname
    networking.hostName = "prod-main";
  };
}