{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      perSystem = flake-utils.lib.eachSystem [ "aarch64-linux" ] (system:
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

      # Flattened alias so you can reference #prod-master directly
      "prod-master" = perSystem.nixosConfigurations."prod-master";
    };
}