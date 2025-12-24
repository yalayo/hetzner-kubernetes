{
  description = "HA k3s cluster managed with Colmena";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, colmena, ... }:
  let
    system = "aarch64-linux";
    nixpkgsPkgs = import nixpkgs { inherit system; };
    hive = import ./hive.nix;
  in {
    colmena = hive // {
      meta = {
        nixpkgs = nixpkgsPkgs;
      };
    };
  };
}
