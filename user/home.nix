{ username, config, lib, pkgs, ... }:

# Main user's `home.nix` for home manager.

{

  home.username = username;
  home.homeDirectory = "/home/${username}";

  imports = [
    ./../modules/overlay.nix
    ./annoyance.nix
    ./desktop.nix
  ];

  # Caches patched NUR Nix expression to prevent refetch.
  home.file.".nix-gc-roots/overlay".text = let
    patchedExpressions = import ./../modules/system/patchedExpressions.nix;
  in builtins.toString (pkgs.callPackage patchedExpressions.nur-rycee { });

  home.packages = with pkgs; [ curl gocryptfs sshfs ];

  # Makes a convenient mount point for FUSE.
  home.file."mnt/.keep".text = "";

  home.persistence = config.customization.persistence.other;

  services.autorandr = {
    enable = true;
    ignoreLid = true;
  };

  programs.autorandr = {
    enable = true;
    profiles = config.customization.autorandrProfiles { inherit lib pkgs; };
    hooks.preswitch = {
      "reset-warmth" = "${lib.getExe pkgs.redshift} -x";
    };
    hooks.postswitch = {
      "change-brightness" = "${lib.getExe pkgs.brightnessctl} set 20%";
      "change-warmth" = "${lib.getExe pkgs.redshift} -O 4000";
      "change-background" = "${lib.getExe pkgs.nitrogen} --restore";
    };
  };

  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

}
