{ config, pkgs, lib, k3s ? { token = ""; }, ... }: # Accept k3s.token as flake arg

let
  helmBinary = pkgs.helm;
  # Helm chart versions can be fixed here or overridden
  traefikChartVersion = "37.0.0"; 
  cloudflaredChartVersion = "1.7.1"

  # Helm install commands as scripts
  installTraefik = ''
    ${helmBinary}/bin/helm upgrade --install traefik traefik/traefik \
      --namespace kube-system \
      --set dashboard.enabled=true \
      --set rbac.enabled=true \
      --version ${traefikChartVersion}
  '';

  installCloudflared = ''
    ${helmBinary}/bin/helm upgrade --install cloudflared cloudflare/cloudflared \
      --namespace kube-system \
      --version ${cloudflaredChartVersion}
  '';
in {
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

    environment.systemPackages = with pkgs; [ vim jq helm ];

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

  system.activationScripts.k3sHelmDeploy = {
    text = ''
      # Wait for k3s to be active (adjust if needed)
      until kubectl get nodes &> /dev/null; do sleep 3; done

      # Add Helm repos if not added
      if ! ${helmBinary}/bin/helm repo list | grep traefik; then
        ${helmBinary}/bin/helm repo add traefik https://helm.traefik.io/traefik
      fi
      if ! ${helmBinary}/bin/helm repo list | grep cloudflare; then
        ${helmBinary}/bin/helm repo add cloudflare https://cloudflare.github.io/helm-charts
      fi
      ${helmBinary}/bin/helm repo update

      # Install Traefik
      ${installTraefik}

      # Install Cloudflared
      ${installCloudflared}
    '';
  };
}