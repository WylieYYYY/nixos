{ persist, lib, pkgs, ... }:

# Collection of configurations to reduce annoyance.
# Disables first run notifications and popups.
# Requires `xmlAttrset.nix` for generating XML documents for LibreOffice.  
# - persist: Attribute set of persisting settings.
#   - bluemanNoNotification?: whether to suppress Blueman notifications (defaults to true).

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
  lib.mkIf (persist.bluemanNoNotification or true) {
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

  # Stops VLC from asking for network metadata access.
  # Don't need metadata for media.
  xdg.configFile."vlc/vlcrc".text = lib.generators.toINI { } {
    qt.qt-privacy-ask = 0;
    core.metadata-network-access = 0;
  };

}
