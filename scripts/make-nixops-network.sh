#!/usr/bin/env bash
set -euo pipefail

# Usage: make-nixops-network.sh terraform-output.json
infile=${1:-terraform/terraform-output.json}
out=network.nix

# Extract and normalize values regardless of whether they are wrapped in .value
jq -r '
  {
    server: (if .first_node_ip.value? then .first_node_ip.value else .first_node_ip end),
    workers: (if .nodes_ips.value? then .nodes_ips.value else .nodes_ips end)
  }' "$infile" > /tmp/inventory.json

SERVER_IP=$(jq -r .server /tmp/inventory.json)
WORKER_IPS=$(jq -r '.workers | @sh' /tmp/inventory.json)

cat > "$out" <<EOF
{ config, pkgs, lib, ... }:

let
  k3sToken = ""; # can be filled via nixops deployment or secrets
in {
  # shared defaults
  deployment.targetEnv = "existing";
  networking.firewall.enable = true;
  time.timeZone = "UTC";

  prod-main = { config, pkgs, ... }: {
    networking.hostName = "prod-main";
    services.openssh.enable = true;
    services.k3s = {
      enable = true;
      role = "server";
      clusterInit = true;
      extraFlags = [ "--disable=traefik" ];
    };
    deployment.targetHost = "${SERVER_IP}";
    deployment.sshUser = "root";
  };

# workers
EOF

# Append worker definitions
i=1
for ip in $(jq -r '.workers[]' /tmp/inventory.json); do
  cat >> "$out" <<EOF

prod-worker-${i} = { config, pkgs, ... }: {
  networking.hostName = "prod-worker-${i}";
  services.openssh.enable = true;
  services.k3s = {
    enable = true;
    role = "agent";
    token = ""; # token will be read from server or provided
  };
  deployment.targetHost = "${ip}";
  deployment.sshUser = "root";
};
EOF
  i=$((i+1))
done

echo "Generated $out"
