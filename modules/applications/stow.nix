{ config, lib, pkgs, ... }:

# Stow configurations.

let
  cfg = config.programs.stow;

  dirModule = lib.types.submodule {
    options = {
      target = lib.mkOption {
        type = lib.types.path;
        apply = builtins.toString;
        description = "Location to install the packages.";
      };
      dotfiles = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use the dotfiles option for this Stow directory.";
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Package names within the Stow directory.";
      };
    };
  };
in

{

  options.programs.stow = {
    enable = lib.mkEnableOption "stow, a symlink farm manager";

    dirs = lib.mkOption {
      type = lib.types.attrsOf dirModule;
      description = "Attribute set of Stow directories to their settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services = lib.mkMerge (lib.mapAttrsToList (name: value: {
      "stow-${builtins.replaceStrings [ "/" "." ] [ "-" "_" ] name}" = {
        Unit.Description = "stow packages from ${name}";
        Install.WantedBy = [ "default.target" ];
        Service.ExecStart = lib.concatStringsSep " " ([
          (lib.getExe' pkgs.stow "stow")
        ] ++ lib.optional value.dotfiles "--dotfiles" ++ [
          "--dir ${lib.escapeShellArg name}"
          "--target ${lib.escapeShellArg value.target}"
          "--stow ${lib.escapeShellArgs value.packages}"
        ]);
      };
    }) cfg.dirs);
  };

}
