{
  description = "HA k3s cluster managed with Colmena";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, colmena, ... }: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "aarch64-linux";
        };
      };

      imports = [
        ./hive.nix
      ];
    };
  };
}
