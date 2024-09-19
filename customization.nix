{ home-manager-repo, impermanence-repo, config, lib, pkgs, ... }:

# Modulized NixOS configuration customizations.

let
  userModule = pkgs.callPackage ./user/customization.nix {
    inherit home-manager-repo impermanence-repo;
    bareSubmodule = true;
  };

  isolatedModule = lib.types.submodule {
    options = {
      entries = lib.mkOption {
        type = with lib.types; functionTo (attrsOf (attrsOf str));
        default = lib.const { };
        description = ''
          Function yielding a nested attribute set of user names to isolated item names to shell script strings.
        '';
      };
      nftOutputRules = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Additional NFTables output rules.";
      };
    };
  };

  globalPersistenceModule = let
    mkNullablePathOption = description: lib.mkOption {
      inherit description;
      type = lib.types.nullOr lib.types.path;
      default = null;
      apply = path: (
        if path == null
        then null
        else builtins.toString path
      );
    };
  in lib.types.submodule {
    options = {
      boot = lib.mkOption {
        type = lib.types.submodule {
          options = {
            efi = mkNullablePathOption "Path to the EFI mount point, typically under `grub` path and named `efi`.";
            grub = mkNullablePathOption "GRUB boot directory.";
          };
        };
        default = { };
      };
      machineState = mkNullablePathOption "Directory for machine-specific states such as authentication.";
      root = mkNullablePathOption "Directory for system user data.";
      syncthing = mkNullablePathOption "Directory to be shared to all devices provided.";
      wallpaper = mkNullablePathOption "Display manager background image file.";
    };
  };

  globalModule = lib.types.submodule {
    options = {
      allowedUnfreePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Unfree package names to allow.";
      };
      isolated = lib.mkOption {
        type = isolatedModule;
        default = { };
        description = "Configurations for isolating execution to another user.";
      };
      network = lib.mkOption {
        type = lib.types.submodule {
          options = {
            dns = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "A list of DNS server addresses with optional domain fragments.";
            };
            dnssecExcludes = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "A list of domains to be excluded from DNSSEC.";
            };
            hostname = lib.mkOption {
              type = lib.types.str;
              default = "nixos";
              description = "Host name to be registered.";
            };
            syncthingIds = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Attribute set of device names to Syncthing IDs.";
            };
          };
        };
        default = { }; 
      };
      persistence = lib.mkOption {
        type = globalPersistenceModule;
        default = { };
        description = "Configurations for persisting files.";
      };
      swapDevicePartUuid = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Swap partition's UUID for encryption.";
      };
    };
  };
in

{

  options.customization = {
    users = lib.mkOption {
      type = with lib.types; attrsOf (either userModule path);
      default = { };
      apply = builtins.mapAttrs (_: value:
        value // { inherit (config.customization) global; }
      );
      description = ''
        Path to the user's `home.nix` configuration file.
        Or a configuration module for the included Home Manager configurations,
        for which the module can be found in `user/customization.nix`.
      '';
    };
    global = lib.mkOption {
      type = globalModule;
      default = { };
      description = "Global configurations readable by all users.";
    };
  };

}
