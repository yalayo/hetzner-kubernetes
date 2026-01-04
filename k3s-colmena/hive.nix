let
  nodesJson = builtins.fromJSON (builtins.readFile ./terraform.json);

  mkNode = name: ip: {
    deployment = {
      targetHost = ip;
      targetUser = "root";
    };

    # Explicitly set the hostname to match the attribute name
    networking.hostName = name;

    imports = [ ./node.nix ];
  };
in
builtins.mapAttrs mkNode nodesJson
