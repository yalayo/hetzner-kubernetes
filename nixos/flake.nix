{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    # optional: allow overriding the token from outside
    k3s-token = {
      # placeholder; overridden via --override-input or by generating this file dynamically
      # Example usage: nixos-anywhere --override-input k3s-token "mysecret"
      url = "github:dummy/dummy"; # dummy so input exists; we only care about the value passed in
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem ["aarch64-linux"] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Extract the token; this will come from overridden input if provided
        k3sToken = if builtins.hasAttr "rev" self.inputs."k3s-token" then
          # In real usage, you'd structure this to pass the token via an attr or a secret file.
          builtins.getEnv "K3S_TOKEN" or ""
        else
          "";
        config = {
          imports = [ ./k3s-node.nix ];
          system.stateVersion = "24.11";
          # Example: expose the k3s token into the module via an option override
          environment.etc."k3s-token".text = k3sToken;
        };
      in {
        nixosConfigurations."prod-master" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ config ];
        };
      }
    );
}