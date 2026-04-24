{ config, lib, pkgs, ... }:

# Allows directory to be created without a file within it.
# This is useful for creating mount points.

let
  cfg = config.home.directory;

  directoryModule = lib.types.submodule {
    options.mode = lib.mkOption {
      type = lib.types.strMatching "[0-7]{3}";
      default = "755";
      description = "Directory permission for the created directory.";
    };
  };
in

{

  options.home.directory = lib.mkOption {
    type = lib.types.attrsOf directoryModule;
    default = { };
    description = "Attribute set of destination directory paths relative to home to directories.";
  };

  config.home.activation = lib.mkMerge (lib.mapAttrsToList (name: value: let
    escapedName = lib.escapeShellArg (lib.removePrefix config.home.homeDirectory name);
  in {
    "${name}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir --parent $VERBOSE_ARG "$HOME"/${escapedName}
      $DRY_RUN_CMD chmod $VERBOSE_ARG ${value.mode} "$HOME"/${escapedName}
    '';
  }) cfg);

}
