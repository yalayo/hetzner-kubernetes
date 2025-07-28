{ config, pkgs, ... }:

{
  imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];

  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "mymachine";

  time.timeZone = "UTC";

  users.users.root = {
    initialPassword = "changeme";
  };

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;

  environment.systemPackages = with pkgs; [
    git
    curl
  ];
}