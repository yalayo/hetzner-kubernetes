let
  tf = builtins.fromJSON (builtins.readFile ./terraform.json);

  nodes = tf.k3s_nodes.value;

  mkNode = name: ip: {
    deployment.targetHost = ip;
    deployment.targetUser = "root"; # Hetzner default
    imports = [ ./node.nix ];
  };
in
{
  meta = {
    nixpkgs = import <nixpkgs> {};
  };
}
// builtins.mapAttrs mkNode nodes
