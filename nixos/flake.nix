{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nixosConfigurations.prod-master = pkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./k3s-node.nix ]; # your configuration module
          # you can also add additional configuration overlays/overrides here
        };
      });
}