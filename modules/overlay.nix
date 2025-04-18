{ config, lib, ... }:

# Applications to be added and used as an overlay.
# todo: Put expressions and extension bundles here.

let
  nur = (import ./system/patchedExpressions.nix).nur-rycee;
  applications = {
    cson                             = ./applications/pkgs/cson.nix;
    distro-grub-themes               = ./applications/pkgs/distro-grub-themes.nix;
    firefox-addons.cubicle           = ./applications/extensions/firefox-cubicle.nix;
    firefox-addons.seventv           = ./applications/extensions/firefox-7tv.nix;
    gitlab-ci-local                  = ./applications/pkgs/gitlab-ci-local.nix;
    lua52Packages.awesome-ez         = ./applications/pkgs/awesome-ez.nix;
    noto-cjk-mono                    = ./applications/pkgs/noto-cjk-mono.nix;
    nur.repos.rycee                  = { pkgs, ... }: pkgs.callPackage "${pkgs.callPackage nur { }}" { };
    shellfront                       = ./applications/pkgs/shellfront.nix;
    piptube                          = ./applications/pkgs/piptube.nix;
  };

  callPackagesWithPathInAttrs = pkgs: lib.mapAttrsRecursive (path: value:
    [{ inherit path; update = _: pkgs.callPackage value { inherit config; }; }]
  ) applications;
  updates = pkgs: lib.flatten (lib.collect builtins.isList
      (callPackagesWithPathInAttrs pkgs));
in

{
  config.nixpkgs.overlays = [
    (final: prev: lib.updateManyAttrsByPath (updates prev) prev)
    (final: prev: {
      libadwaita = prev.libadwaita.overrideAttrs (old: {
        doCheck = false;
        patches = (old.patches or [ ]) ++ [(prev.fetchpatch {
          url = "https://aur.archlinux.org/cgit/aur.git/plain/theming_patch.diff?h=libadwaita-without-adwaita-git&id=f62cef1b969e42d4812858ea524e38bc46aa7b47";
          sha256 = "ytiApwVBQqFUQb28tFQ74AQZ0dad54/mCRu1Zd1fxNc=";
        })];
      });
    })
  ] ++ config.customization.global.nixpkgsOverlays;
}
