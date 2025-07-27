{ bareSubmodule, home-manager-repo, impermanence-repo, config, lib, pkgs, ... }:

# Modulized Home Manager configuration customizations.

let
  gitConfigModule = lib.types.submodule {
    options = {
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default email associated with Git.";
      };
      username = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default user name associated with Git.";
      };
    };
  };

  persistenceModule = let
    mkNullablePathOption = _: description: lib.mkOption {
      inherit description;
      type = lib.types.nullOr lib.types.path;
      default = null;
      apply = path: (
        if path == null
        then null
        else builtins.toString path
      );
    };
    other = let
      homeManagerImpermanenceModule = pkgs.callPackage "${impermanence-repo}/home-manager.nix" { };
    in lib.mkOption {
      type = homeManagerImpermanenceModule.options.home.persistence.type;
      default = { };
      description = "Other files to be persisted in the impermanence module format.";
    };
  in lib.types.submodule {
    options = ((builtins.mapAttrs mkNullablePathOption {
      browser = "Directory for persisting extensions.json, extension-settings.json.";
      direnv = "Directory for persisting Direnv allow records.";
      kdbx = "Default Keepass file for password managers' quick access.";
      piptube = "PiPTube JAR file.";
      wallpaper = "Wallpaper image file.";
    }) // { inherit other; });
  };

  userModule = lib.types.submodule {
    options = {
      hashedPassword = lib.mkOption {
        type = lib.types.str;
        description = "Hashed password for the user.";
      };
      autorandrProfiles = let
        autorandrModule = pkgs.callPackage "${home-manager-repo}/modules/programs/autorandr.nix" { };
      in lib.mkOption {
        type = lib.types.functionTo autorandrModule.options.programs.autorandr.profiles.type;
        default = lib.const { };
        description = "Autorandr profiles specification.";
      };
      bluemanNoNotification = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to suppress Blueman connection notifications.";
      };
      codeEditor = lib.mkOption {
        type = with lib.types; nullOr (enum [ "pulsar" "vscodium" ]);
        default = null;
        description = "Code editor to be enabled.";
      };
      containerSuffixes = lib.mkOption {
        type = with lib.types; attrsOf (listOf str);
        default = { };
        description = ''
          Attribute set of container names to their suffixes.
          `useCubicleExtension` must be true for this to take effect.
        '';
      };
      git = lib.mkOption {
        type = gitConfigModule;
        default = { };
        description = "Configurations for Git.";
      };
      global = lib.mkOption {
        type = lib.types.anything;
        readOnly = true;
        description = "Mirror of the global customization for accessing within Home Manager configuration.";
      };
      gummiTexlivePackages = lib.mkOption {
        type = with lib.types; functionTo (listOf (attrsOf anything));
        default = texlive: with texlive; [ scheme-basic texcount ];
        description = "TeX Live packages to be bundled with Gummi.";
      };
      mouseAllowedDomainRegexes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Domain regular expressions that are excluded from Tridactyl's no mouse mode.";
      };
      trackedTickers = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Tickers to be tracked by the Conky widget.";
      };
      useCubicleExtension = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether the browser persisting directory has a build of Cubicle to link.
          Enables the extension with the name `cubicle.xpi` under the persisting directory.
        '';
      };
      windowManager = lib.mkOption {
        type = lib.types.enum [ "awesome" "openbox" ];
        default = "awesome";
        description = "Window manager to use, Awesome has better multi-screen support and customization.";
      };
      persistence = lib.mkOption {
        type = persistenceModule;
        default = { };
        description = "Configurations for persisting files within user's home directory.";
      };
    };
  };
in

if bareSubmodule
then userModule
else {
  options.customization = lib.mkOption {
    type = userModule;
  };
}
