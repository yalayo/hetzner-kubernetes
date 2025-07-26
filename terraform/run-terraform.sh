#!/usr/bin/env bash
set -euo pipefail

# Make sure nix is explicitly in PATH
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:$PATH"

terraform init
terraform apply -auto-approve