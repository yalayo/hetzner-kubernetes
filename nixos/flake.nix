{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" ];
      perSystem = flake-utils.lib.eachSystem systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          nixosConfigurations = {
            "prod-master" = pkgs.lib.nixosSystem {
              inherit system;
              modules = [ ./k3s-node.nix ];
            };
          };
        });
    in {
      inherit perSystem;

      # Flattened convenience alias: prod-master refers to the aarch64 one.
      prod-master = perSystem."aarch64-linux".nixosConfigurations."prod-master";
    };
}