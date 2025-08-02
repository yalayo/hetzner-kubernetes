{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      systems = [ "aarch64-linux" ];
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
    in
    {
      inherit perSystem;

      # Flattened alias so you can do `#prod-master`
      nixosConfigurations = perSystem.nixosConfigurations;
      "prod-master" = perSystem.nixosConfigurations."prod-master";

      # Also keep the system namespace if you want the fully qualified one
      aarch64-linux = perSystem;
    }
}