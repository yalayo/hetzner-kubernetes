{ config, pkgs, lib, modulesPath, ... }:

{
  options.k3s.token = lib.mkOption {
    type = lib.types.str;
    description = "K3S cluster token";
  };

  config = {
    imports = [
      "${modulesPath}/installer/scan/not-detected.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
      ./disk-config.nix
    ];

    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    services.openssh.enable = true;

    environment.systemPackages = with pkgs; [
      curl
      gitMinimal
    ];

    users.users.root.openssh.authorizedKeys.keys =
      [
        "# CHANGE"
      ] ++ (config.extraPublicKeys or []);  # note: this `config` here is the module’s merged config; it works.

    system.stateVersion = "24.11";
  };
}