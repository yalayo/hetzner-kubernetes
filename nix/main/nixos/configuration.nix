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

  users.users.root.openssh.authorizedKeys.keys =
  [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSSk8xXcuwN2Ws7tw/6avEYZbi4CUPQfEFb3EO3ea2hhHv/fccs5GzwGK1gAgVpujTUUwqceeEm9WlpEe7x7aksmn+ghBPKpgACT4VFUh/6IjySVi6PKhxhUtD4SyXEobwkKQxgKCjKv2OUD/Eu2QUK6xZwwrobDlwHv8WZr74mKs/+nugPQBVQhDmmU3aCol/emrTpCeYrQO4sy2/4LkK857zSQH777SqXgOT+8iRrkQe7NeDR/FSt/omn65LvBNcbFnh14/x/EC+UP6gKpvEapUmiJ6QXZ3gN0dmUFv3yECKrW5FPVuABjaQNtIBkJZ9bsJgna7iXKgqQMRePLxh ssh-key-2023-04-27"
  ];

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
  ];

  system.stateVersion = "24.11";
}