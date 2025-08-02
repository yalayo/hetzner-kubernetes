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
            prod-master = pkgs.lib.nixosSystem {
              inherit system;
              modules = [ ./k3s-node.nix ];
            };
          };
        });

      # Build the packages / legacyPackages shape expected by nixos-anywhere
      packagesAttr = builtins.mapAttrs (system: attrs: {
        nixosConfigurations = {
          prod-master = attrs.nixosConfigurations.prod-master;
        };
      }) perSystem;
    in {
      inherit perSystem;

      packages = packagesAttr;
      legacyPackages = packagesAttr;

      # Top-level alias for the real target
      nixosConfigurations = {
        prod-master = perSystem."aarch64-linux".nixosConfigurations.prod-master;
      };
      prod-master = perSystem."aarch64-linux".nixosConfigurations.prod-master;
    };
}