args@{ home-manager-repo, impermanence-repo, config, lib, pkgs, ... }:

# Multi-user configurations with home manager.

let
  mainUsernames = builtins.attrNames config.customization.users;
  isolatedUsernames = builtins.attrNames (config.customization.global.isolated.entries { inherit lib pkgs; });
in

{

  imports = [
    "${home-manager-repo}/nixos"
    ./modules/system/isolatedUsers.nix
  ];

  # Caches patched home manager Nix expression to prevent refetch.
  system.extraDependencies = [ home-manager-repo ];

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

  security.sudo.execWheelOnly = true;

  # Disables sudo lecture as the lecture state is reset with impermanence.
  security.sudo.extraConfig = "Defaults lecture = never";

  # Configures the same groups and shell for all main users.
  # todo: Fine tune groups and shell for each user when needed.
  users.users = lib.mkMerge (lib.imap0 (index: name: {
    "${name}" = {
      inherit (config.customization.users."${name}") hashedPassword;
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

  # Setup home manager with impermanence module.
  # Main users can customize paths to their `home.nix`,
  # isolated users' `home.nix` should be located at `isolated/<name>.nix`.
  home-manager.users = let
    isViaCustomization = name: builtins.hasAttr name args.config.customization.users &&
        builtins.isAttrs args.config.customization.users."${name}";
  in lib.mkMerge (builtins.map (props: {
    "${props.name}" = home-args@{ config, lib, pkgs, ... }: {
      imports = [
        "${impermanence-repo}/home-manager.nix"
        (import "${./.}/${props.path}" (home-args // {
          username = props.name;
        }))
      ] ++ lib.optional (isViaCustomization props.name) (
        import ./user/customization.nix (home-args // {
          inherit (args) home-manager-repo impermanence-repo;
          bareSubmodule = false;
        })
      );
    } // (
      if isViaCustomization props.name
      then { customization = args.config.customization.users."${props.name}"; }
      else { }
    );
  }) (
    (builtins.map (name: {
      inherit name;
      path = if isViaCustomization name
             then "user/home.nix"
             else config.customization.users."${name}";
    }) mainUsernames) ++
    (builtins.map (name: {
      inherit name;
      path = "isolated/${name}.nix";
    }) isolatedUsernames)
  ));

}
