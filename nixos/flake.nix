{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      prod-master = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ ./k3s-node.nix ];
      };
    };
  };
}