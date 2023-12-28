{ config, lib, pkgs, ... }:

# Allows managed files to be writable by applications.
# Instead of linking read-only file from store, copy in place on Home Manager activation.
# This is useful as some applications reset configurations if the file permission is incorrect.

let
  cfg = config.home.writableFile;

  fileModule = lib.types.submodule {
    options = {
      mode = lib.mkOption {
        type = lib.types.strMatching "[0-7]{3}";
        default = "644";
        description = "File permission for the copied file.";
      };
      source = lib.mkOption {
        type = lib.types.path;
        description = "Source file to be put in the store and copied in place on activation.";
      };
    };
  };
in

{
  options.home.writableFile = lib.mkOption {
    type = lib.types.attrsOf fileModule;
    default = { };
    description = "Attribute set of destination file paths relative to home to files.";
  };

  config.home.activation = lib.mkMerge (lib.mapAttrsToList (name: value: let
    escape = lib.escapeShellArg;
    file = builtins.path {
      name = builtins.replaceStrings [ "/" ] [ "-" ] name;
      path = value.source;
    };
  in {
    "${name}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir --parent $VERBOSE_ARG $(dirname "$HOME"/${escape name})
      $DRY_RUN_CMD install --mode ${value.mode} --no-target-directory $VERBOSE_ARG \
      ${file} "$HOME"/${escape name}
    '';
  }) cfg);
}
