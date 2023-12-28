{ config, lib, ... }:

# Runs applications as isolated users, lessens file exposure.
# This gives main users `sudo` rights to the isolated users.

let
  cfg = config.users;

  # Extra group configurations for main users to gain file access.
  mainUserConfig = isolatedUsernames: mainUsername: {
    "${mainUsername}".extraGroups = isolatedUsernames;
  };

  # User configurations for isolated users.
  isolatedUserConfig = index: name: {
    "${name}" = {
      uid = cfg.isolated.idOffset + index;
      isSystemUser = true;
      group = name;
      createHome = true;
      home = "${cfg.isolated.isolatedUserHomeBaseDir}/${name}";
    };
  };
in

{

  options.users.isolated = {
    mainUsernames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users that are allowed to run applications as isolated users.";
    };

    isolatedUsernames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users that are used to run applications in isolation.";
    };

    isolatedUserHomeBaseDir = lib.mkOption {
      type = lib.types.path;
      default = /home;
      apply = builtins.toString;
      description = "Base directory for isolated users' homes.";
    };

    idOffset = lib.mkOption {
      type = lib.types.ints.positive;
      default = 800;
      description = "The start of isolated users' UIDs, counting up.";
    };
  };

  config = {
    security.sudo.extraRules = (builtins.map (name: {
      users = cfg.isolated.mainUsernames;
      runAs = name;
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }) cfg.isolated.isolatedUsernames);

    users.groups = lib.mkMerge (lib.imap0 (index: name: {
      "${name}" = { gid = cfg.isolated.idOffset + index; };
    }) cfg.isolated.isolatedUsernames);

    users.users = lib.mkMerge (
      (lib.imap0 isolatedUserConfig cfg.isolated.isolatedUsernames) ++
      (builtins.map (mainUserConfig cfg.isolated.isolatedUsernames) cfg.isolated.mainUsernames)
    );

    fileSystems = lib.mkMerge (builtins.map (name: {
      "${cfg.isolated.isolatedUserHomeBaseDir}/${name}" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "mode=770"
          "uid=${builtins.toString cfg.users."${name}".uid}"
          "gid=${builtins.toString cfg.groups."${name}".gid}"
        ];
      };
    }) cfg.isolated.isolatedUsernames);
  };

}
