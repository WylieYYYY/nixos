{ config, lib, ... }:

# Applications to be added and used as an overlay.
# todo: Put expressions and extension bundles here.

let
  nur = (import ./system/patchedExpressions.nix).nur-rycee;
  applications = {
    distro-grub-themes               = ./applications/pkgs/distro-grub-themes.nix;
    firefox-addons.cubicle           = ./applications/extensions/firefox-cubicle.nix;
    firefox-addons.seventv           = ./applications/extensions/firefox-7tv.nix;
    gitlab-ci-local                  = ./applications/pkgs/gitlab-ci-local.nix;
    noto-cjk-mono                    = ./applications/pkgs/noto-cjk-mono.nix;
    nur.repos.rycee                  = { pkgs, ... }: pkgs.callPackage "${pkgs.callPackage nur { }}" { };
    shellfront                       = ./applications/pkgs/shellfront.nix;
    piptube                          = ./applications/pkgs/piptube.nix;
  };
in

{
  config.nixpkgs.overlays = [
    (final: prev: prev // (lib.mapAttrsRecursive (_: value:
      prev.callPackage value { inherit config; }
    ) applications))
    (final: prev: {
      libadwaita = prev.libadwaita.overrideAttrs (old: {
        doCheck = false;
        patches = (old.patches or [ ]) ++ [(prev.fetchpatch {
          url = "https://aur.archlinux.org/cgit/aur.git/plain/theming_patch.diff?h=libadwaita-without-adwaita-git&id=685390ce7c5d5614c6b0db545b60a3412262584f";
          sha256 = "hUtUewagY7ZqgOWKgK5VhE/v3twJZto7G/o4S/gwlBk=";
        })];
      });
    })
  ];
}
