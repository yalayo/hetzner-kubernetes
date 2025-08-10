{
  description = "k3s cluster managed by NixOps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    kubernetes.url = "github:nix-community/kubernetes";
    nixops.url = "github:NixOS/nixops";
  };

  outputs = { self, nixpkgs, flake-utils, kubernetes, nixops, ... }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      k8s  = kubernetes.lib;
    in {
      packages.traefikManifests = let
        traefikRelease = k8s.helm.release {
          name = "traefik";
          namespace = "kube-system";
          chart = "traefik";
          repo  = "https://helm.traefik.io/traefik";
            version = "37.0.0"; # updateable
          values = {
            service = { type = "NodePort"; };
            deployment = { kind = "DaemonSet"; };
            ingressClass = { enabled = true; isDefaultClass = true; };
          };
        };
      in traefikRelease.resources;

      packages.cloudflaredManifests = let
        cloudflaredRelease = k8s.helm.release {
          name = "cloudflared";
          namespace = "kube-system";
          chart = "cloudflared";
          repo  = "https://cloudflare.github.io/helm-charts";
            version = "0.2.0"; # example, check latest
          values = {
            tunnel = { name = "ingress-tunnel"; };
            credentials = { existingSecret = "cloudflared-credentials"; };
          };
        };
      in cloudflaredRelease.resources;

      cloudflaredCredentialsSecret = k8s.lib.mkSecret {
        metadata = {
          name = "cloudflared-credentials";
          namespace = "kube-system";
        };
        stringData = {
          "credentials.json" = ''
            {
              "AccountTag": "your-account-tag",
              "TunnelSecret": "your-tunnel-secret",
              "TunnelID": "your-tunnel-id",
              "TunnelName": "my-tunnel"
            }
          '';
        };
        type = "Opaque";
      };

      packages.k8sResources = self.packages.traefikManifests ++ self.packages.cloudflaredManifests ++ [ self.cloudflaredCredentialsSecret ];

      nixopsConfigurations.k3sHetzner = {
        network = import ./network.nix;
        # reference k8sResources for deployment here
      };
    }
  );
}