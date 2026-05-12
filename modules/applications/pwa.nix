{ config, lib, pkgs, ... }:

let
  cfg = config.programs.pwa;

  overlayModule = lib.types.submodule {
    options = {
      workdir = lib.mkOption {
        type = lib.types.path;
        apply = builtins.toString;
        description = "An empty directory on the same filesystem as the upper directory.";
      };
      upperdir = lib.mkOption {
        type = lib.types.path;
        apply = builtins.toString;
        description = "Mutable upper directory to be overlaid onto common browser options.";
      };
    };
  };

  profileModule = lib.types.submodule {
    options = {
      overlay = lib.mkOption {
        type = lib.types.nullOr overlayModule;
        default = null;
        description = "Overlay options when the profile should use common browser options.";
      };
      site = lib.mkOption {
        type = lib.types.anything;
        description = "Site options for firefoxpwa.";
      };
    };
  };

  profilesWithOverlay = lib.filterAttrs (_: profile: profile.overlay != null) cfg.profiles;
in

{

  options.programs.pwa = {
    enable = lib.mkEnableOption ''
      pwa, progressive web application
      with common browser options and overlay.
    '';

    profiles = lib.mkOption {
      type = lib.types.attrsOf profileModule;
      default = { };
      description = "Attribute set of ULID profile names to profiles.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefoxpwa = {
      enable = true;

      profiles = builtins.mapAttrs (name: profile: {
        sites."${name}" = profile.site;
      }) cfg.profiles;
    };

    systemd.user.services = lib.mkMerge (lib.mapAttrsToList (name: profile: {
      "pwa-overlay-${name}" = {
        Unit = {
          Description = "overlay for PWA ${name}";
          Before = [ "default.target" ];
        };
        Service.ExecStart = lib.getExe (pkgs.writeShellScriptBin "pwa-overlay-${name}-exec-start" ''
          ${lib.getExe' pkgs.coreutils "mkdir"} --parent ${lib.escapeShellArg config.xdg.dataHome}/firefoxpwa/profiles/${name} &&
          ${lib.getExe pkgs.fuse-overlayfs} -f \
              ${lib.escapeShellArg config.xdg.dataHome}/firefoxpwa/profiles/${name} \
              -o lowerdir=${lib.escapeShellArg config.home.homeDirectory}/.librewolf/pwa \
              -o upperdir=${lib.escapeShellArg profile.overlay.upperdir} \
              -o workdir=${lib.escapeShellArg profile.overlay.workdir}
        '');
        Install.WantedBy = [ "basic.target" ];
      };
    }) profilesWithOverlay);

    programs.librewolf = lib.mkIf (profilesWithOverlay != { }) {
      enable = true;

      profiles.pwa = {
        id = 255;

        settings = {
          "browser.download.folderList" = 0;
          "browser.tabs.inTitlebar" = 0;
          "browser.uidensity" = 1;
          "firefoxpwa.linksTarget" = 2;
          "network.http.referer.XOriginPolicy" = 2;

          # some options that are used in the full browser but missing in PWA
          "network.trr.mode" = 5;
          "privacy.resistFingerprinting" = true;
        };
        search = rec {
          force = true;
          default = "ddg";
        };
        extensions.packages = [
          pkgs.nur.repos.rycee.firefox-addons.ublock-origin
        ];
      };
    };
  };

}
