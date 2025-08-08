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
    {
        nixosConfigurations.prod-secondary = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
                disko.nixosModules.disko
                ./configuration.nix
                ./k3s-node.nix
            ];
            specialArgs = {
                k3s = {
                    token = builtins.getEnv "K3S_TOKEN"; # Accept from `--option k3s.token ...`
                };
            };
        };
    };
}