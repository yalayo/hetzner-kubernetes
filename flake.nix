{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.colmena
    pkgs.jq
    pkgs.kubectl
  ];
}