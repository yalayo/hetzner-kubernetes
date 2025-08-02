{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
    ./disk-config.nix
    ./k3s-options.nix
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
    ] ++ (config.extraPublicKeys or []);

  # Now you can set the token elsewhere, e.g. via an overlay or another imported file:
  # k3s.token = "your-secret-token";

  system.stateVersion = "24.11";
}