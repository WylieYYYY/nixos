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
  services.udiskie.enable = true;

  # Syncthing with predefined folder shared to all devices.
  services.syncthing = lib.mkIf (config.customization.persistence.syncthing != null) {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = lib.mkMerge (lib.mapAttrsToList (name: value:
        { "${name}".id = value; }
      ) config.customization.syncthingIds);
      folders.sync = {
        path = config.customization.persistence.syncthing;
        devices = builtins.attrNames config.customization.syncthingIds;
      };
    };
  };

  services.autorandr.enable = true;

  programs.autorandr = {
    enable = true;
    profiles = config.customization.autorandrProfiles { inherit lib pkgs; };
    hooks.postswitch = {
      "refresh-otd-screens" = "${lib.getExe' pkgs.systemd "systemctl"} restart --user opentabletdriver.service";
      "change-brightness" = "${lib.getExe pkgs.brightnessctl} set 20%";
      "change-warmth" = "${lib.getExe pkgs.redshift} -x && ${lib.getExe pkgs.redshift} -O 4000";
    } // (lib.optionalAttrs (config.customization.windowManager == "awesome") {
      "restart-awesome" = "{ sleep 2s; ${lib.getExe' pkgs.awesome "awesome-client"} 'awesome.restart()' & } &";
    });
  };

  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

}
