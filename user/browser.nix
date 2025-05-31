{ config, lib, pkgs, ... }:

# Adds browser and extensions.

let
  cfg = config.programs.librewolf;
  nur = pkgs.nur.repos.rycee.firefox-addons;

  # Profile name of the default profile, any will do.
  profileName = "default";

  # Extensions to install, mutable for building symlink manually below.
  immutableExtensions = [
    nur.darkreader
    nur.tridactyl
    nur.ublock-origin
    pkgs.firefox-addons.seventv
  ];
  mutableExtensions = lib.optional (config.customization.useCubicleExtension)
      pkgs.firefox-addons.cubicle;

  # Predicatable UUIDs for extensions, allows for setting new tab page.
  extensionUuidMap = let
    addonIds = builtins.map (extension: extension.meta.addonId) (immutableExtensions ++ mutableExtensions);
    # randomly generated UUID namespace.
    uuidNamespace = "aefb136e-fa1f-40f4-9f8b-f2e742e5460e";
  in lib.genAttrs addonIds (addonId:
    (builtins.readFile (pkgs.runCommand "generate-uuid-${addonId}" { } ''
      ${lib.getExe' pkgs.libuuid "uuidgen"} --sha1 --namespace ${uuidNamespace} \
          --name ${lib.escapeShellArg addonId} | \
          ${lib.getExe' pkgs.coreutils "tr"} --delete '\n' > $out
    ''))
  );
in

{

  imports = [
    ./../modules/applications/cubicle.nix
    ./../modules/system/writableHomeFile.nix
  ];

  home.file = with pkgs.firefox-addons; lib.mapAttrs' (name:
    lib.nameValuePair "${cfg.configPath}/${profileName}/${name}"
  ) {
    # Persists extension registry to suppress new installation warning.
    "extensions.json" = lib.mkIf (config.customization.persistence.browser != null) {
      source = config.lib.file.mkOutOfStoreSymlink
          "${config.customization.persistence.browser}/extensions.json";
    };
    # Symlink for building and reloading Cubicle extension.
    "extensions/${cubicle.meta.addonId}.xpi" = lib.mkIf (config.customization.useCubicleExtension) {
      source = config.lib.file.mkOutOfStoreSymlink "${config.customization.persistence.browser}/cubicle.xpi";
    };
    # Stops 7TV popup everytime the website is launched.
    "browser-extension-data/${seventv.meta.addonId}/storage.js".text = builtins.toJSON {
      seen_onboarding = true;
      upgraded = true;
    };
    # Adds annoyances and cookie notices filters.
    "browser-extension-data/${nur.ublock-origin.meta.addonId}/storage.js".text = builtins.toJSON {
      selectedFilterLists = [
        "user-filters"
        "ublock-filters"
        "ublock-badware"
        "ublock-privacy"
        "ublock-quick-fixes"
        "ublock-unbreak"
        "easylist"
        "easyprivacy"
        "LegitimateURLShortener"
        "adguard-spyware-url"
        "urlhaus-1"
        "curben-phishing"
        "plowe-0"
        "fanboy-cookiemonster"
        "ublock-cookies-easylist"
        "adguard-cookies"
        "ublock-cookies-adguard"
        "easylist-chat"
        "easylist-newsletters"
        "easylist-notifications"
        "easylist-annoyances"
        "adguard-mobile-app-banners"
        "adguard-other-annoyances"
        "adguard-popup-overlays"
        "adguard-widgets"
        "ublock-annoyances"
      ];
    };
  };

  # Suppresses browser warning for new tab change.
  # If this file is not writable, the browser will replace it with a reset file.
  home.writableFile."${cfg.configPath}/${profileName}/extension-settings.json" =
      lib.mkIf (config.customization.persistence.browser != null) {
    source = "${config.customization.persistence.browser}/extension-settings.json";
  };

  programs.librewolf = rec {
    enable = true;

    nativeMessagingHosts = [ pkgs.tridactyl-native ];

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
        "security.OCSP.enabled" = 0;
        "xpinstall.signatures.required" = false;

        "places.history.enabled" = false;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
        "privacy.clearOnShutdown_v2.siteSettings" = true;
      };
      search = rec {
        force = true;
        default = "ddg";
        privateDefault = default;
        order = [ default "google" ];
      };
      extensions.packages = immutableExtensions;
    };
  };

  programs.cubicle = lib.mkIf (config.customization.useCubicleExtension) {
    enable = true;
    inherit profileName;

    containers."Work" = lib.mkIf (config.customization.containerSuffixes ? Work) {
      color = "blue";
      icon = "briefcase";
      suffixes = config.customization.containerSuffixes.Work;
    };
  };

  # Tridactyl configurations for cursorless browsing.
  xdg.configFile."tridactyl/tridactylrc".text = let
    mouseAllowedRegex = lib.concatStringsSep "|" (config.customization.mouseAllowedDomainRegexes ++ [
      "0\\.0\\.0\\.0" "127\\.0\\.0\\.1" "localhost"
    ]);
  in ''
    bind m mouse_mode
    bind s hint -;
    colors dark

    autocmd DocLoad ^https?://(?!(?:${mouseAllowedRegex})(?:[:/]|$)) no_mouse_mode
    autocmd DocLoad ^https://search\.nixos\.org/ unfocus
    autocmd UriChange ^https://search\.nixos\.org/ unfocus
    autocmd DocLoad ^https://www\.twitch\.tv/ hint -c main .simplebar-scroll-content
  '';

}
