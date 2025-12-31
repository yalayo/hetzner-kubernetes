{
  description = "HA k3s cluster managed with Colmena";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, colmena, ... }:
  let
    system = "aarch64-linux";
    hive = import ./hive.nix;
  in {
    colmena = {
      nodes = hive.nodes;

      meta = {
        nixpkgs = nixpkgs.url;  #pass the URL, not the full pkgs
      };
    };
  };
}
