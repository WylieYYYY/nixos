{ config, lib, pkgs, ... }:

{

  imports = [ <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix> ];

  virtualisation.diskImage = null;

}
