{ lib, ... }:

# Applications to be added and used as an overlay.
# todo: Put expressions and extension bundles here.

let
  applications = {
    distro-grub-themes               = ./applications/distro-grub-themes.nix;
    firefox-addons.seventv           = ./applications/extensions/firefox-7tv.nix;
    gitlab-ci-local                  = ./applications/gitlab-ci-local.nix;
    nur.repos.rycee                  = (import ./system/patchedExpressions.nix).nur-rycee; 
  };
in

{
  config.nixpkgs.overlays = [(final: prev: prev // (lib.mapAttrsRecursive (_: value:
    prev.callPackage value { }
  ) applications))];
}
