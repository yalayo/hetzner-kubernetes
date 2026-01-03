{
  description = "HA k3s cluster managed with Colmena";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, colmena, ... }:
  let
    system = "aarch64-linux";

    pkgs = import nixpkgs {
      inherit system;
      overlays = [];
      config = {};
    };

    hive = import ./hive.nix;

    nodesJson = builtins.fromJSON (builtins.readFile ./terraform.json);
    nodeNames = builtins.attrNames nodesJson;
  in {
    colmena = {
      nodes = hive;

      meta = {
        nixpkgs = pkgs;
        nodeNixpkgs = builtins.mapAttrs (_: _: pkgs) hive;

        # CORRECT way to pass shared data
        specialArgs = {
          clusterNodes = nodesJson;
          clusterNodeNames = nodeNames;
        };
      };
    };
  };
}
