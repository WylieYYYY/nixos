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
      firefoxpwa-unwrapped = prev.firefoxpwa-unwrapped.override {
        firefoxRuntime = prev.librewolf-unwrapped;
      };
    })
    (final: prev: let
      libadwaitaOverride = package: package.override {
        libadwaita = prev.libadwaita.overrideAttrs (old: {
          doCheck = false;
          patches = (old.patches or [ ]) ++ [(prev.fetchpatch {
            url = "https://aur.archlinux.org/cgit/aur.git/plain/theming_patch.diff?h=libadwaita-without-adwaita&id=4a304803a89cdefab0d7523ac0155eaf5f9ec962";
            sha256 = "xE6ZYeNIKiq+vXlF0ByrAg/JEQ3wbzab4XkjVRtPFVA=";
          })];
        });
      };
    in {
      file-roller = libadwaitaOverride prev.file-roller;
    })
  ] ++ config.customization.global.nixpkgsOverlays;
}
