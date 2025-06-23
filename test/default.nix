{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, ... }:

let
  configuration = pkgs.stdenv.mkDerivation {
    name = "vm-configuration";

    srcs = [ ./. ];
    sourceRoot = ".";

    installPhase = ''
      mkdir $out
      cp --recursive ${./..}/* $out
      cp --force ${./vm-hardware-configuration.nix} $out/hardware-configuration.nix
      rm $out/persist.nix
      cp --force ${./vm-persist.nix} $out/persist.nix
    '';
  };

  build-vm = pkgs.writeShellScriptBin "build-vm" ''
    [ -z "$1" ] && { echo 'Please specify the NixOS version as the first argument.'; exit; }
    ${lib.getExe' pkgs.nix "nix-build"} '<nixpkgs/nixos>' -A vm --show-trace \
        -I nixpkgs=channel:nixos-"$1" -I nixos-config=${configuration}/configuration.nix
  '';
in

pkgs.mkShell {
  buildInputs = [ build-vm ];
}
