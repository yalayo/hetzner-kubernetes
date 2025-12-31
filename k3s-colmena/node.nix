{ config, lib, pkgs, ... }:

let
  nodes = builtins.attrNames config.colmena.nodes;
  sortedNodes = lib.sort builtins.lessThan nodes;
  isClusterInit = config.networking.hostName == builtins.head sortedNodes;

  apiHostname = "kube.example.com";
in
{
  networking.firewall.allowedTCPPorts = [
    6443
    2379
    2380
    10250
  ];

  networking.firewall.allowedUDPPorts = [
    8472
  ];

  services.k3s = {
    enable = true;
    role = "server";

    clusterInit = isClusterInit;
    serverAddr  = "https://${apiHostname}:6443";

    extraFlags = lib.concatStringsSep " " (
      [
        "--disable traefik"
        "--disable servicelb"
        "--disable-cloud-controller"
        "--write-kubeconfig-mode=644"
        "--protect-kernel-defaults"
      ]
      ++ map (name:
        "--tls-san ${config.colmena.deployment.nodes.${name}.deployment.targetHost}"
      ) nodes
      ++ [
        "--tls-san ${apiHostname}"
      ]
    );
  };

  environment.systemPackages = with pkgs; [
    kubectl
  ];

  ### Cloudflared tunnel (API LB)
  services.cloudflared = {
    enable = true;

    tunnels.k3s-api = {
      credentialsFile = "/var/lib/cloudflared/k3s-api.json";

      ingress = {
        "${apiHostname}" = {
          service = "https://localhost:6443";
          originRequest.noTLSVerify = true;
        };

        "http_status:404" = {};
      };
    };
  };
}
