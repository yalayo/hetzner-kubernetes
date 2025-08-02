# configuration.nix
{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
    ./disk-config.nix
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
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
      # change this to your ssh key
      "# CHANGE"
    ] ++ (config.extraPublicKeys or []); # if you’re passing extraPublicKeys via specialArgs

    options.k3s.token = lib.mkOption {
        type = lib.types.str;
        description = "K3S cluster token";
    };

  system.stateVersion = "24.11";
}