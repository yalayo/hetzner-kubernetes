let
  nodesJson = builtins.fromJSON (builtins.readFile ./terraform.json);

  mkNode = name: ip: {
    deployment = {
      targetHost = ip;
      targetUser = "root";
    };

    networking.hostName = name;

    imports = [ ./node.nix ];
  };
in
{
  nodes = builtins.mapAttrs mkNode nodesJson;
}
