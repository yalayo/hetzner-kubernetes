let
  nodesJson = builtins.fromJSON (builtins.readFile ./terraform.json);

  mkNode = name: ip: {
    deployment = {
      targetHost = ip;
      targetUser = "root";
    };

    imports = [ ./node.nix ];
  };
in
builtins.mapAttrs mkNode nodesJson
