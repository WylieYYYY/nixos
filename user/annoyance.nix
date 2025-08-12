{ config, lib, pkgs, ... }:

# Collection of configurations to reduce annoyance.
# Disables first run notifications and popups.

let
  xmlAttrset = pkgs.callPackage ./../modules/utils/xmlAttrset.nix { };
in

{

  # Some applications like to replace configuration files,
  # trusts Home Manager and lets it overwrite them.
  home.activation.checkLinkTargets = lib.mkForce "";

  # Blueman prompts for auto power on when first run,
  # make it false to stop it.
  dconf.settings."org/blueman/plugins/powermanager" = with lib.hm.gvariant; {
    auto-power-on = mkJust (mkBoolean false);
  };

  # Suppresses connection notification,
  # annoying after the icon is patched to display connection status.
  dconf.settings."org/blueman/general" = with lib.hm.gvariant;
      lib.mkIf (config.customization.bluemanNoNotification) {
    plugin-list = mkArray type.string [ "!ConnectionNotifier" ];
  };

  # Although LibreOffice replaces read-only file, it respects existing configurations.
  # Disables the tip of the day popup.
  xdg.configFile."libreoffice/4/user/registrymodifications.xcu" = {
    source = xmlAttrset.createOrdered rec {
      list = [(lib.nameValuePair "item" {
        "@oor:path" = "/org.openoffice.Office.Common/Misc";
        prop = {
          "@oor:name" = "ShowTipOfTheDay";
          "@oor:op" = "fuse";
          value."text()" = "false";
        };
      })];
      filepath = xmlAttrset.createRoot root {
        oor = "http://openoffice.org/2001/registry";
        xs = "http://www.w3.org/2001/XMLSchema";
        xsi = "http://www.w3.org/2001/XMLSchema-instance";
      };
      root = "oor:items";
      useNs = false;
    };
  };

  # Trusted substituters and public keys for the system will be trusted by users as well.
  xdg.dataFile."nix/trusted-settings.json".text = builtins.toJSON {
    extra-trusted-public-keys."${lib.concatStringsSep " " config.customization.global.trustedPublicKeys}" = true;
    extra-substituters."${lib.concatStringsSep " " config.customization.global.trustedSubstituters}" = true;
  };

  # Stops VLC from asking for network metadata access.
  # Don't need metadata for media, and do not resize when the video changes.
  xdg.configFile."vlc/vlcrc".text = lib.generators.toINI { } {
    qt.qt-notification = 0;
    qt.qt-privacy-ask = 0;
    qt.qt-video-autoresize = 0;
    core.metadata-network-access = 0;
  };

}
