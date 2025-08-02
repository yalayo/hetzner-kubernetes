{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" ];
      perSystemList = flake-utils.lib.eachSystem systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          system = system;
          nixosConfigurations = {
            prod-master = pkgs.lib.nixosSystem {
              inherit system;
              modules = [ ./k3s-node.nix ];
            };
          };
        });
      perSystem = builtins.listToAttrs (map (item: {
        name = item.system;
        value = item;
      }) perSystemList);
    in {
      inherit perSystem;

      nixosConfigurations = {
        prod-master = perSystem."aarch64-linux".nixosConfigurations.prod-master;
      };
      prod-master = perSystem."aarch64-linux".nixosConfigurations.prod-master;
    };
}