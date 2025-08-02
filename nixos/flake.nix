{
  description = "k3s aarch64 Hetzner prod-master";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs =
    {
        nixpkgs,
        disko,
        nixos-facter-modules,
        ...
    }:
    let
      lib = nixpkgs.lib;
      # Conditionally include the extra SSH key module if it was created by your workflow
      extraKeyModule = lib.optional (builtins.pathExists ./nixos/extra-keys.nix) ./nixos/extra-keys.nix;
    in {
        nixosConfigurations.prod-master = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
                disko.nixosModules.disko
                ./configuration.nix
                ./k3s-node.nix
            ] ++ extraKeyModule;
        };
    };
}