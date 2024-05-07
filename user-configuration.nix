args@{ impermanence-repo, persist, config, lib, pkgs, ... }:

# Multi-user configurations with home manager.
# Parameters:
# - impermanence-repo: Filesystem path to the root of the impermanence module repository.
# - persist: Attribute set of persisting settings.
#   - isolatedEntries?: Function yielding an attribute set of user names to isolated menu entries.
#     - expects: { lib, pkgs, ... }:
#         { <username> = { name = <application name>; value = <command>; }, ... }
#   - users?: Attribute set of main usernames to user specific configurations.
#     - <username>?: The username.
#       - hashedPassword: Hashed password in the shadow format.
#       - homeNixPath: Path to the user's `home.nix` configuration file.
#  - ...?: Additional list of options found in `user/home.nix`.

let
  # Imports and patches home manager for custom configuration.
  home-manager-nix = (import <nixpkgs> { }).callPackage
      (import ./modules/system/patchedExpressions.nix).home-manager { };

  mainUsernames = lib.optionals (persist ? users) builtins.attrNames persist.users;
  isolatedUsernames = lib.optionals (persist ? isolatedEntries)
      builtins.attrNames (persist.isolatedEntries { inherit lib pkgs; });
in

{

  imports = [
    "${home-manager-nix}/nixos"
    ./modules/system/isolatedUsers.nix
  ];

  # Caches patched home manager Nix expression to prevent refetch.
  system.extraDependencies = [ home-manager-nix ];

  users.isolated = { inherit mainUsernames isolatedUsernames; };

  services.accounts-daemon.enable = true;

  # Uses a PNG file as the account icon if it exists.
  system.activationScripts = lib.mkMerge (builtins.map (user: let
    ini = pkgs.writeText "account-icon" (lib.generators.toINI { } {
      User.Icon = "/var/lib/AccountsService/icons/${user}.png";
    });
  in {
    "accountsservice-${user}" = lib.stringAfter [ "var" ] ''
      mkdir --parent /var/lib/AccountsService/users
      cp --remove-destination ${ini} /var/lib/AccountsService/users/${user}
    '';
  }) (mainUsernames ++ isolatedUsernames));

  programs.fish.enable = true;

  users.mutableUsers = false;

  # Disables sudo lecture as the lecture state is reset with impermanence.
  security.sudo.extraConfig = "Defaults lecture = never";

  # Configures the same groups and shell for all main users.
  # todo: Fine tune groups and shell for each user when needed.
  users.users = lib.mkMerge (lib.imap0 (index: name: {
    "${name}" = {
      inherit (persist.users."${name}") hashedPassword;
      uid = 1000 + index;
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "bluetooth" "syncthing" ];
      shell = pkgs.fish;
    };
  }) mainUsernames);

  # Mounts all main users' homes as tmpfs for impermanence.
  fileSystems = lib.mkMerge (lib.imap0 (index: name: {
    "/home/${name}" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "mode=700" "uid=${builtins.toString (1000 + index)}"
        "gid=${builtins.toString config.users.groups.users.gid}"
      ];
    };
  }) mainUsernames);

  # Setup home manager with impermanence module and `persist` parameter.
  # Main users can customize paths to their `home.nix`,
  # isolated users' `home.nix` should be located at `isolated/<name>.nix`.
  home-manager.users = lib.mkMerge (builtins.map (props: {
    "${props.name}" = args@{ config, lib, pkgs, ... }: {
      imports = [
        "${impermanence-repo}/home-manager.nix"
        (import "${./.}/${props.path}" (args // {
          inherit persist;
          username = props.name;
        }))
      ];
    };
  }) (
    (builtins.map (name: {
      inherit name;
      path = persist.users."${name}".homeNixPath;
    }) mainUsernames) ++
    (builtins.map (name: {
      inherit name;
      path = "isolated/${name}.nix";
    }) isolatedUsernames)
  ));

}
