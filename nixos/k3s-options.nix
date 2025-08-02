{ lib, ... }:

{
  options.k3s.token = lib.mkOption {
    type = lib.types.str;
    description = "K3S cluster token";
    default = "";
  };
}