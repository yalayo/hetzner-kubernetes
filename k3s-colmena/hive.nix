let
  nodesJson = builtins.fromJSON (builtins.readFile ./terraform.json);
  nodeNames = builtins.attrNames nodesJson;

  mkNode = name: ip: {
    deployment = {
      targetHost = ip;
      targetUser = "root";
    };

    networking.hostName = name;

    _module.args = {
      clusterNodes = nodesJson;
      clusterNodeNames = nodeNames;
    };

    imports = [ ./node.nix ];
  };
in
builtins.mapAttrs mkNode nodesJson
