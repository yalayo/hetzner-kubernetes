let
  nodesJson = builtins.fromJSON (builtins.readFile ./terraform.json);
  nodeNames = builtins.attrNames nodesJson;

  mkNode = name: ip: {
    deployment = {
      targetHost = ip;
      targetUser = "root";
    };

    networking.hostName = name;

    # pass cluster data INTO the module
    _module.args = {
      clusterNodes = nodesJson;
      clusterNodeNames = nodeNames;
    };

    imports = [ ./node.nix ];
  };
in
{
  nodes = builtins.mapAttrs mkNode nodesJson;
}
