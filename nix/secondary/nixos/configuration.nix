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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCG7F9b8suFVGBZYGQHOLJi4rgrXvD5DPPfVN7NwvlEXW+StvMi1+xJQr/pHHBEYVcD1psrJd4GWCiMKW2lbGCDn4ijaw5am4wesVKs8AzGoJ/I1J5wwVk0+qRPG3BTq4hkJhDqf/lAh+Do9EcSVCgc8dnpalwquFT/0RuNoStodoEXmID2Y23mfIetft6aEIaq+D5mxE/B2846e9pELbeAe1VqAgqpwBWQOzKW8xBuhUtGix4ahuj9CFxuGizFjxXIrfb6bwXN1ejIZNiYw39mzmsy5mtRYcXxGumZLTNNQ5msBAsHRFrqrMcMA1XWdHn4U/joM4GseS3qsQt025yuYM7zfYV3wFUKjhOPvlZIldAmciOYyaGZGz5TQ5e2q3C0OT8fJyUfhQD8KVKGBU+6eO3ursuLBxbC7vDxQ7YD+CWLR0mDrO6w2p2ocpGt8/CCtzbwey7ervnHpjFYMlixqrivTHd8s9+7LmtDfbehcRg0KMw1M87RetBAUUNSFrc= yalayo@w10p689"
  ];

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
  ];

  system.stateVersion = "24.11";
}