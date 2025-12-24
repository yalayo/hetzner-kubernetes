let
  nodes = builtins.fromJSON (builtins.readFile ./terraform.json);

  mkNode = name: ip: {
    deployment = {
      targetHost = ip;
      targetUser = "root";
    };

    imports = [ ./node.nix ];
  };
in
{
  nodes = builtins.mapAttrs mkNode nodes;
}
