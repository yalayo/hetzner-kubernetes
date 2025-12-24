let
  nodes = builtins.fromJSON (builtins.readFile ./terraform.json);

  mkNode = name: ip: {
    deployment.targetHost = ip;
    deployment.targetUser = "root";
    imports = [ ./node.nix ];
  };
in
{
  # nixpkgs must be top-level
  nixpkgs = import <nixpkgs> {};

} // builtins.mapAttrs mkNode nodes
