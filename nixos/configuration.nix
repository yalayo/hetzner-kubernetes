{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
    ./disk-config.nix
    ./k3s-options.nix
    #./extra-keys.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;

  #users.users.root.openssh.authorizedKeys.keys = extraPublicKeys;

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
  ];

  system.stateVersion = "24.11";
}