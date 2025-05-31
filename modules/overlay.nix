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
          url = "https://aur.archlinux.org/cgit/aur.git/plain/theming_patch.diff?h=libadwaita-without-adwaita-git&id=d98b5bc68b2eba95104ee36661af788701f43219";
          sha256 = "3fQ0coWIK00FEngdAp97Cnd0PvHmBoFCxr7gb+AKpgQ=";
        })];
      });
    })
  ] ++ config.customization.global.nixpkgsOverlays;
}
