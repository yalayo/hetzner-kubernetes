{ config, pkgs, lib, k3s ? { token = ""; }, ... }: # Accept k3s.token as flake arg

{
  options.k3s = {
    token = lib.mkOption {
      type = lib.types.str;
      default = "";  # Use specialArg default
      description = "Shared k3s cluster token";
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
      token = "placeholder";
      clusterInit = true;
      extraFlags = [
        "--tls-san=10.1.1.1"
        "--disable=traefik"
      ];
    };

    # Time
    time.timeZone = "UTC";
    services.timesyncd.enable = true;

    # Hostname
    networking.hostName = "prod-main";
  };
}