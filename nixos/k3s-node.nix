{ config, pkgs, lib, ... }:

let
  fileToken = if builtins.pathExists /etc/k3s-token
    then builtins.readFile /etc/k3s-token
    else "";

  # Role marker file: either "init" or "https://<first-ip>:6443"
  roleInfo = if builtins.pathExists /etc/k3s-role then builtins.readFile /etc/k3s-role else "";
  isInit = roleInfo == "init"; # simple check
  joinServerFromFile = if roleInfo != "init" && roleInfo != "" then roleInfo else "";
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
      effectiveToken = lib.mkForce (if config.k3s.token != "" then config.k3s.token else fileToken);
      # Prefer the role file over module options for clusterInit / serverAddr
      useClusterInit = isInit || config.k3s.clusterInit;
      joinAddr = if !isInit && joinServerFromFile != "" then joinServerFromFile else config.k3s.joinServer;
    in {
      enable = true;
      role = "server";
      token = effectiveToken;
      clusterInit = useClusterInit;
      # k3s wants --server=<url> to join; the option is often exposed as serverAddr or similar depending on your module
      serverAddr = joinAddr;
    };

    # Boot loader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Time
    time.timeZone = "UTC";
    services.timesyncd.enable = true;

    # Hostname
    networking.hostName = "cluster-node";
  };
}