{ config, lib, pkgs, ... }:

# Pulsar Edit configurations.

let
  cfg = config.programs.pulsar;
  buildAtomPackage = pkgs.callPackage ./extensions/buildAtomPackage.nix { };

  packageModule = lib.types.submodule {
    options = {
      repo = lib.mkOption {
        type = lib.types.str;
        description = "Name of the GitHub repository to fetch the package from.";
      };
      owner = lib.mkOption {
        type = lib.types.str;
        description = "Owner of the GitHub repository.";
      };
      version = lib.mkOption {
        type = lib.types.str;
        description = "Version of the package which is the tag name without the `v` prefix.";
      };
      sha256 = lib.mkOption {
        type = lib.types.str;
        description = "Hash value of the specific version of the package repository.";
      };
      packageLock = lib.mkOption {
        type = with lib.types; nullOr (either path str);
        default = null;
        description = ''
          `null` if external `package-lock.json` is not required,
          path to the file otherwise. This file is not patched and assumed to have a
          `packages` key in the root of the object. If there is no `packages` key,
          use `npmDepsHash` to specify dependencies hash. Default is `null`.
        '';
      };
      npmDepsHash = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Hash of NPM dependencies for old version lock file support.
          If this is not null, the `packageLock` option is ignored. Default is `null`.
        '';
      };
      patches = lib.mkOption {
        type = with lib.types; listOf (nullOr (either path str));
        default = [ ];
        description = "Patches to be applied to the package. Default is an empty list.";
      };
    };
  };
in

{

  imports = [ ./../system/writableHomeFile.nix ];

  options.programs.pulsar = {
    enable = lib.mkEnableOption "pulsar, a community-led hyper-hackable text editor";

    packages = lib.mkOption {
      type = lib.types.listOf packageModule;
      default = [ ];
      description = "List of Atom packages to be installed.";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Set of configurations to be added to `config.cson`.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.pulsar ];

    home.file = lib.mkMerge (builtins.map (package: let
      builtPackage = buildAtomPackage package;
    in {
      ".pulsar/packages/${builtPackage.pname}".source =
          "${builtPackage}/lib/node_modules/${builtPackage.pname}";
    }) cfg.packages);

    home.writableFile.".pulsar/config.cson".source = pkgs.runCommand "pulsar-config-cson" { } ''
      printf '%s\n' ${lib.escapeShellArg (builtins.toJSON cfg.config)} |
          ${lib.getExe' pkgs.cson "cson"} --json2cson --stdin $out
    '';
  };

}
