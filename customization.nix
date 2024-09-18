{ home-manager-repo, impermanence-repo, config, lib, pkgs, ... }:

# Modulized NixOS configuration customizations.

let
  userModule = pkgs.callPackage ./user/customization.nix {
    inherit home-manager-repo impermanence-repo;
    bareSubmodule = true;
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
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Global freeform configurations readable by all users.";
    };
  };

}
