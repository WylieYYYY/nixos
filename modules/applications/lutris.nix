{ config, lib, pkgs, ... }:

# Lutris configurations.

let
  cfg = config.programs.lutris;
  platform = builtins.elemAt (builtins.split "-" pkgs.system) 0;
  runnerList = (builtins.fromJSON (builtins.readFile (pkgs.fetchurl {
    url = "https://lutris.net/api/runners";
    sha256 = cfg.runnerListSha256;
  }))).results;

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
        default = null;
        description = "Hash value for the version artifact.";
      };
    };
  };

  # Installer specific options.
  installerModule = lib.types.submodule {
    options = {
      slug = lib.mkOption {
        type = lib.types.str;
        description = "Slug for the installer.";
      };
      sha256 = lib.mkOption {
        type = lib.types.str;
        default = null;
        description = "Hash value for the installer script.";
      };
    };
  };

  # Game specific options.
  gameModule = lib.types.submodule {
    options = {
      bannerSha256 = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hash value for the banner art.";
      };
      installer = lib.mkOption {
        type = installerModule;
        apply = installer: builtins.elemAt (builtins.fromJSON (builtins.readFile (pkgs.fetchurl {
          url = "https://lutris.net/api/installers/${installer.slug}?format=json";
          inherit (installer) sha256;
        }))).results 0;
        description = "Slug for the installer.";
      };
    };
  };

  # Fetches the online listing and match the version and architecture.
  # todo: Add cache option for the listing in case Lutris remove runners.
  downloadDetail = runnerName: version: (lib.findFirst (variant:
    variant.version == version && variant.architecture == platform
  ) null (lib.findFirst (runner: runner.slug == runnerName) null runnerList).versions).url;

  # Fetches and gets the correct path to install the runner to.
  generateRunnerFiles = name: instances: let
    nestedName = version: if name == "wine" then "/${version}-${platform}" else ""; 
  in (builtins.map (instance: {
    "lutris/runners/${name}${nestedName instance.version}" = {
      source = pkgs.fetchzip {
        url = downloadDetail name instance.version;
        sha256 = instance.sha256;
      };
    };
  }) instances);
in

{

  imports = [ ./../system/writableHomeFile.nix ];

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

    gameDirectory = lib.mkOption {
      type = lib.types.str;
      description = "Parent directory for games.";
    };

    games = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf gameModule;
      };
      default = { };
      description = "Registered games in the database.";
    };

    runners = lib.mkOption {
      type = lib.types.submodule {
        freeformType = with lib.types; attrsOf (listOf runnerModule);
      };
      default = { };
      description = "Runner names to version list.";
    };

    runnerListSha256 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hash value for the runner list.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = lib.mkMerge (builtins.map (game: lib.mkIf (game.bannerSha256 != null) {
      "${config.xdg.cacheHome}/lutris/banners/${game.installer.game_slug}.jpg"
          .source = pkgs.fetchurl {
        url = "https://lutris.net/games/banner/${game.installer.game_slug}.jpg";
        sha256 = game.bannerSha256;
      };
    }) (builtins.attrValues cfg.games));

    xdg.configFile = let
      installers = builtins.map (game: {
        "lutris/games/${game.installer.slug}.yml".text = builtins.replaceStrings
            [
              "$GAMEDIR"
              "STAGING_SHARED_MEMORY: 1"
              "WINE_LARGE_ADDRESS_AWARE: 1"
              "__GL_SHADER_DISK_CACHE: 1"
            ]
            [
              "${cfg.gameDirectory}/${game.installer.game_slug}"
              "STAGING_SHARED_MEMORY: '1'"
              "WINE_LARGE_ADDRESS_AWARE: '1'"
              "__GL_SHADER_DISK_CACHE: '1'"
            ]
            game.installer.content;
      }) (builtins.attrValues cfg.games);
    in lib.mkMerge ([{
      "lutris/system.yml".text = lib.generators.toYAML { } {
        system = cfg.globalOptions;
      };
    }] ++ installers);

    xdg.dataFile = lib.mkMerge (lib.foldlAttrs (acc: name: value:
      acc ++ generateRunnerFiles name value
    ) [ ] cfg.runners);

    home.writableFile."${config.xdg.dataHome}/lutris/pga.db".source = let
      escape = builtins.replaceStrings [ "'" ] [ "''" ];
      insertStatements = (lib.foldlAttrs(acc: name: value: acc + ''
        INSERT INTO games (
          name, slug, installer_slug, platform, runner,
          directory, installed, installed_at, configpath
        ) VALUES (
          '${escape name}', '${escape value.installer.game_slug}',
          '${escape value.installer.slug}',
          'NixOS', '${escape value.installer.runner}',
          '${escape cfg.gameDirectory}/${escape value.installer.game_slug}',
          1, 0, '${escape value.installer.slug}'
        );
      '') "" cfg.games);
    in pkgs.runCommand "lutris-db" { } ''
      ${lib.getExe pkgs.sqlite} $out <<EOF
        CREATE TABLE games (
          id INTEGER PRIMARY KEY,
          name TEXT,
          sortname TEXT,
          slug TEXT,
          installer_slug TEXT,
          parent_slug TEXT,
          platform TEXT,
          runner TEXT,
          executable TEXT,
          directory TEXT,
          updated DATETIME,
          lastplayed INTEGER,
          installed INTEGER,
          installed_at INTEGER,
          year INTEGER,
          configpath TEXT,
          has_custom_banner INTEGER,
          has_custom_icon INTEGER,
          has_custom_coverart_big INTEGER,
          playtime REAL, hidden INTEGER,
          service TEXT,
          service_id TEXT,
          discord_id TEXT
        );
        ${insertStatements}
      EOF
    '';
  };
}
