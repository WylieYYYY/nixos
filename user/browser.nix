{ persist, config, lib, pkgs, ... }:

# Adds browser and extensions.
# Parameters:
# - persist: Attribute set of persisting settings.
#   - browserPersistPath: Persisting directory for browser.
#     - expects: extensions.json, extension-settings.json
#   - useCubicleExtension?: Whether the persisting directory has a build of Cubicle to link.

let
  cfg = config.programs.firefox;
  nur = pkgs.nur.repos.rycee.firefox-addons;

  # Profile name of the default profile, any will do.
  profileName = "default";

  # Extensions to install, mutable for building symlink manually below.
  extensions = [
    nur.darkreader
    nur.tridactyl
    nur.ublock-origin
    pkgs.firefox-addons.seventv
  ];
  mutableExtensions = lib.optional (persist.useCubicleExtension or false)
      pkgs.firefox-addons.cubicle;

  # Predicatable UUIDs for extensions, allows for setting new tab page.
  extensionUuidMap = let
    addonIds = builtins.map (extension: extension.meta.addonId) (extensions ++ mutableExtensions);
    # randomly generated UUID namespace.
    uuidNamespace = "aefb136e-fa1f-40f4-9f8b-f2e742e5460e";
  in lib.genAttrs addonIds (addonId:
    (builtins.readFile (pkgs.runCommand "generate-uuid-${addonId}" { } ''
      ${lib.getExe' pkgs.libuuid "uuidgen"} --sha1 --namespace ${uuidNamespace} \
          --name ${lib.escapeShellArg addonId} | tr --delete '\n' > $out
    ''))
  );
in

{

  imports = [ ./../modules/system/writableHomeFile.nix ];

  # Rollback Librewolf version, latest version available is buggy.
  # todo: Remove version override once a newer version is available.
  nixpkgs.overlays = [(final: prev: let
    librewolf119 = ((import (prev.fetchFromGitHub {
      owner = "nixos";
      repo = "nixpkgs";
      rev = "0b74f7fd8d5085b4aadbc0ff6eda1a68cf4d3f57";
      sha256 = "0PdoR7zR5aFASBsQ2+WFCNi+gxg/7782ZbGfMvp9fQM=";
    })) { }).librewolf;
  in {
    librewolf = librewolf119.override {
      nativeMessagingHosts = [ pkgs.tridactyl-native ];
    };
  })];

  home.file = with pkgs.firefox-addons; lib.mapAttrs' (name:
    lib.nameValuePair "${cfg.profilesPath}/${profileName}/${name}"
  ) {
    # Persists extension registry to suppress new installation warning.
    "extensions.json".source = config.lib.file.mkOutOfStoreSymlink
        "${persist.browserPersistPath}/extensions.json";
    # Symlink for building and reloading Cubicle extension.
    "extensions/${cubicle.meta.addonId}.xpi" = lib.mkIf (persist.useCubicleExtension or false) {
      source = config.lib.file.mkOutOfStoreSymlink "${persist.browserPersistPath}/cubicle.xpi";
    };
    # Stops 7TV popup everytime the website is launched.
    "browser-extension-data/${seventv.meta.addonId}/storage.js".text = builtins.toJSON {
      seen_onboarding = true;
      upgraded = true;
    };
  };

  # Suppresses browser warning for new tab change.
  # If this file is not writable, the browser will replace it with a reset file.
  home.writableFile."${cfg.profilesPath}/${profileName}/extension-settings.json".source =
      "${persist.browserPersistPath}/extension-settings.json";

  programs.firefox = rec {
    enable = true;
    package = pkgs.librewolf;
    firefoxConfigPath = ".librewolf";
    profilesPath = firefoxConfigPath;

    profiles."${profileName}" = rec {
      settings = let
        tridactylUuid = extensionUuidMap."${nur.tridactyl.meta.addonId}";
        # Escapes the extension IDs for UI customization option.
        escapeAddonId = extension: lib.concatStrings (builtins.map (segment:
          if builtins.isList segment
          then builtins.elemAt segment 0
          else lib.optionalString (segment != "") "_"
        ) (builtins.split "([0-9A-Za-z-]+)" extension.meta.addonId)) + "-browser-action";
        uiCustomization = {
          currentVersion = 19;
          placements = {
            unified-extensions-area = builtins.map escapeAddonId [
              nur.darkreader
              pkgs.firefox-addons.seventv
            ];
            nav-bar = [
              "back-button" "forward-button" "stop-reload-button"
              "customizableui-special-spring1" "urlbar-container"
              "customizableui-special-spring2" "downloads-button"
            ]
            ++ builtins.map escapeAddonId (mutableExtensions ++ [ nur.ublock-origin ])
            ++ [ "fxa-toolbar-menu-button" "unified-extensions-button" ];
          };
        };
      in {
        "browser.download.folderList" = 0;
        "browser.newtab.extensionControlled" = true;
        "browser.startup.homepage" = "moz-extension://${tridactylUuid}/static/newtab.html";
        "browser.tabs.inTitlebar" = 0;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.uiCustomization.state" = uiCustomization;
        "browser.uidensity" = 1;
        "extensions.webextensions.uuids" = extensionUuidMap;
        "xpinstall.signatures.required" = false;
      };
      inherit extensions;
    };
  };

  # Tridactyl configurations for cursorless browsing.
  xdg.configFile."tridactyl/tridactylrc".text = ''
    bind s hint -;
    colors dark

    autocmd DocLoad .* no_mouse_mode
    autocmd DocLoad ^https://search.nixos.org/ unfocus
    autocmd UriChange ^https://search.nixos.org/ unfocus
    autocmd DocLoad ^https://www.twitch.tv/ hint -c main .simplebar-scroll-content
  '';

}
