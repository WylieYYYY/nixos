{ config, lib, pkgs, ... }:

# Nitrogen configurations.

let
  cfg = config.programs.nitrogen;

  modes = [ "scaled" "centered" "tiled" "zoomed" "zoomed-fill" ];
  modeIndexMap = builtins.listToAttrs (lib.imap1 (lib.flip lib.nameValuePair) modes);
in

{
  options.programs.nitrogen = {
    enable = lib.mkEnableOption "nitrogen, a background browser and setter for X windows";

    file = lib.mkOption {
      type = lib.types.path;
      apply = builtins.toString;
      description = "Background image file to use.";
    };

    mode = lib.mkOption {
      type = lib.types.enum modes;
      default = "zoomed-fill";
      apply = (lib.flip builtins.getAttr) modeIndexMap;
      description = "Fitting mode for images that are of different ratios.";
    };

    bgcolor = lib.mkOption {
      type = lib.types.strMatching "#[[:xdigit:]]{6}";
      default = "#000000";
      description = "Background color for empty space.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nitrogen ];

    xdg.configFile."nitrogen/bg-saved.cfg".text = lib.generators.toINI { } {
      "xin_-1" = lib.getAttrs [ "file" "mode" "bgcolor" ] cfg;
    };
  };
}
