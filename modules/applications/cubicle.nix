{ config, lib, pkgs, ... }:

# Cubicle extension configurations.

let
  cfg = config.programs.cubicle;

  cubicle = pkgs.callPackage ./extensions/firefox-cubicle.nix { };
  dataPath = "${config.programs.firefox.profilesPath}/${cfg.profileName}/browser-extension-data";

  # Options for containers.
  containerModule = lib.types.submodule {
    options = {
      color = lib.mkOption {
        type = lib.types.str;
        default = "blue";
        description = "Container color.";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "circle";
        description = "Container icon.";
      };
      suffixes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of suffixes to be associated to the container.";
      };
    };
  };
in

{

  options.programs.cubicle = {
    enable = lib.mkEnableOption "Cubicle, a flexible container manager extension for browsers";

    profileName = lib.mkOption {
      type = lib.types.str;
      description = "Profile name.";
    };

    containers = lib.mkOption {
      type = lib.types.attrsOf containerModule;
      default = { };
      apply = containers: (lib.foldlAttrs (acc: name: value: {
        maxId = acc.maxId + 1;
        containers = acc.containers // { "${name}" = value // { id = acc.maxId; }; };
      }) { maxId = 1; containers = { }; } containers).containers;
      description = "Permanent container configurations.";
    };

    preferences = lib.mkOption {
      type = with lib.types; nullOr (attrsOf anything);
      default = null;
      description = "Cubicle extension preferences.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file."${dataPath}/${cubicle.meta.addonId}/storage.js".text = builtins.toJSON ({
      version = [ 0 1 0 ];
    } // (
      if cfg.preferences == null
      then { }
      else { inherit (cfg) preferences; }
    ) // (lib.mapAttrs' (name: value: let
      cookieStoreId = "firefox-container-${builtins.toString value.id}";
      encodedCookieStoreId = builtins.readFile (pkgs.runCommand "cubicle-handle" { } ''
        echo -n ${lib.escapeShellArg cookieStoreId} | ${lib.getExe' pkgs.coreutils "base64"} | \
            ${lib.getExe' pkgs.coreutils "tr"} --delete '\n' > $out
      '');
      handle = "b64_${builtins.elemAt (builtins.match "([^=]+)=*" encodedCookieStoreId) 0}";
    in lib.nameValuePair handle {
      inherit handle;
      identity = {
        inherit cookieStoreId name;
        inherit (value) color icon;
        colorCode = "#000000";
        iconUrl = "resource://usercontext-content/${value.icon}.svg";
      };
      variant = "Permanent";
      inherit (value) suffixes;
    }) cfg.containers));

    programs.firefox.profiles."${cfg.profileName}".containers = lib.mapAttrs (_: value:
      { inherit (value) id color icon; }
    ) cfg.containers;
  };

}
