{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.terraform
    pkgs.jq
  ];

  # Environment variables
  shellHook = ''
    if [ -n "$TF_API_TOKEN" ]; then
      export TF_TOKEN_app_terraform_io="$TF_API_TOKEN"
    fi

    if [ -n "$HCLOUD_TOKEN" ]; then
      export TF_VAR_hcloud_token="$HCLOUD_TOKEN"
    fi
  '';
}