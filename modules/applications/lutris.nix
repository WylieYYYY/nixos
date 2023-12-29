{ config, lib, pkgs, ... }:

# Lutris configurations.

let
  cfg = config.programs.lutris;
  platform = builtins.elemAt (builtins.split "-" pkgs.system) 0;
  runnerVersions = name: builtins.fetchurl "https://lutris.net/api/runners/${name}";

  # Global options for Lutris.
  globalOptionsModule = lib.types.submodule {
    options = {
      prime = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable NVIDIA Prime Render Offload.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment variables to set for the games.";
      };
    };
  };

  # Runner specific options.
  runnerModule = lib.types.submodule {
    options = {
      version = lib.mkOption {
        type = lib.types.str;
        description = "Specific version of runner to install.";
      };
      sha256 = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Hash value for the version artifact.";
      };
    };
  };

  # Fetches the online listing and match the version and architecture.
  # todo: Add cache option for the listing in case Lutris remove runners.
  downloadDetail = runnerName: version: (lib.findFirst (variant:
    variant.version == version && variant.architecture == platform
  ) null (builtins.fromJSON (builtins.readFile (runnerVersions runnerName))).versions).url;

  # Fetches and gets the correct path to install the runner to.
  generateRunnerFiles = name: instances: let
    nestedName = version: if name == "wine" then "/${version}-${platform}" else ""; 
  in (builtins.map (instance: {
    "lutris/runners/${name}${nestedName instance.version}" = {
      source = builtins.fetchTarball {
        url = downloadDetail name instance.version;
        sha256 = instance.sha256;
      };
    };
  }) instances);
in

{
  options.programs.lutris = {
    enable = lib.mkEnableOption "lutris, an open gaming platform";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lutris-free;
      description = "Package providing Lutris.";
    };

    globalOptions = lib.mkOption {
      type = globalOptionsModule;
      default = { prime = false; };
      description = "Global system options.";
    };

    runners = lib.mkOption {
      type = lib.types.submodule {
        freeformType = with lib.types; attrsOf (listOf runnerModule);
      };
      default = { };
      description = "Runner names to version list.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."lutris/system.yml".text = lib.generators.toYAML { } {
      system = cfg.globalOptions;
    };

    xdg.dataFile = lib.mkMerge (lib.foldlAttrs (acc: name: value:
      acc ++ generateRunnerFiles name value
    ) [ ] cfg.runners);
  };
}
