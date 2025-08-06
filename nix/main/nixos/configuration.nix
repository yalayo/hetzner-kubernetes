{ config, pkgs, lib, modulesPath, ... }:

{
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
  services.openssh.passwordAuthentication = false;

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./id_nixos_anywhere.pub)
  ];

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
  ];

  system.stateVersion = "24.11";
}