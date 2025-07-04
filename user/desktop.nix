args@{ config, lib, pkgs, ... }:

# Adds desktop applications, with some MIME and keybind settings.

let
  xmlAttrset = pkgs.callPackage ./../modules/utils/xmlAttrset.nix { };

  # Browser by default focuses to the address bar on launch,
  # which makes the Tridactyl extension difficult to use.
  librewolf-unfocus = let
    xdotool = lib.getExe pkgs.xdotool;
  in pkgs.writeShellScriptBin "librewolf-unfocus" ''
    ${lib.getExe config.programs.librewolf.finalPackage} $@ &
    while ${xdotool} getwindowfocus getwindowname | grep --invert-match 'LibreWolf'; do
      sleep 0.1s
    done
    ${xdotool} key 'F6'
  '';

  # Changes VLC so that it grabs focus when a new file is opened and plays audio minimized.
  vlc-focus = let
    wmctrl = lib.getExe pkgs.wmctrl;
  in pkgs.writeShellScriptBin "vlc-focus" ''
    codecs="$(${lib.getExe' pkgs.ffmpeg "ffprobe"} -v quiet -show_entries stream=codec_type \
        -of default=noprint_wrappers=1:nokey=1 "$1" | grep --fixed-strings --line-regexp 'video')"
    if [ $# -ne 1 ] || [ $? -eq 0 ]; then
      ${lib.getExe pkgs.vlc} --started-from-file "$@" &

      id=""
      while [ -z "$id" ]; do
        id="$(${wmctrl} -xl | ${lib.getExe pkgs.gawk} '$3 == "vlc.vlc" {print $1}' | \
            ${lib.getExe' pkgs.coreutils "tail"} -1)"
        sleep 0.1s
      done
      ${wmctrl} -ia "$id"
    else
      ${lib.getExe pkgs.vlc} --qt-start-minimized --started-from-file "$1" &
    fi
  '';

  # Application menu that is declared as an expression.
  # Translated for Rofi and Openbox.
  appMenu = let
    entry = lib.nameValuePair;
    # generates isolated application entries to forward calls to specific users.
    isolatedEntries = let
      userForward = userArgs: pkgs.callPackage ./../modules/system/userForward.nix userArgs;
    in lib.mapAttrsToList (name: value:
      entry value.name (userForward { user = name; command = value.value; })
    ) (config.customization.global.isolated.entries { inherit lib pkgs; });
    editorEntry = lib.optional (config.customization.codeEditor != null) ({
      pulsar = entry "Pulsar Edit" (lib.getExe' pkgs.pulsar "pulsar");
      vscodium = entry "VSCodium" pkgs.vscodium;
    })."${config.customization.codeEditor}";
  in with pkgs; [
    "Applications"
    (entry "Accessories" [
      (entry "Archive Manager" file-roller)
      (entry "Mousepad" (lib.getExe' xfce.mousepad "mousepad"))
      (entry "Password Manager" (lib.getExe' keepassxc "keepassxc"))
    ])
    (entry "Internet" ([
      (entry "LibreWolf" librewolf-unfocus)
    ] ++ lib.optionals (config.customization.persistence.piptube != null) [
      (entry "PiPTube" (lib.getExe piptube))
    ]))
  ] ++ lib.optionals (isolatedEntries != [ ]) [
    (entry "Isolated" isolatedEntries)
  ] ++ [
    (entry "Multimedia" [
      (entry "Krita" (lib.getExe' krita "krita"))
      (entry "VLC" (lib.getExe' vlc "vlc"))
    ])
    (entry "Work" ([
      (entry "Gummi" (lib.getExe' gummi "gummi"))
      (entry "LibreOffice" (lib.getExe' libreoffice-still "libreoffice"))
    ] ++ editorEntry ++ [
      (entry "Xournal++" (lib.getExe' xournalpp "xournalpp"))
    ]))
    (entry "File Manager" pcmanfm)
    "System"
    (entry "Terminal" (lib.getExe' xfce.xfce4-terminal "xfce4-terminal"))
    (entry "Reconfigure" { action."@name" = "Reconfigure"; })
    ""
    (entry "Log Out" { action."@name" = "Exit"; })
    (entry "Shutdown" "shutdown now")
  ];

  # Starts applets and enables locking.
  # Inherits display settings from `autorandr`.
  autostart = let
    displaySettings = lib.concatStringsSep "\n" (lib.attrValues
        config.programs.autorandr.hooks.postswitch);
  in with pkgs; ''
    ${displaySettings}
    ${lib.getExe' cbatticon "cbatticon"} &
    ${lib.getExe' networkmanagerapplet "nm-applet"} &
    ${lib.getExe' blueman "blueman-applet"} &
    { sleep 2; ${lib.getExe volctl} & } &
    ${lib.getExe caffeine-ng} &
    ${lib.getExe' lightlocker "light-locker"} &
  '';

  # Keybinds that are valid everywhere, globally.
  globalApplicationKeybinds = with pkgs; {
    "A-f" = "${lib.getExe rofi} -show filebrowser";
    "F1" = "${lib.getExe rofi} -show 'open application'";

    "C-A-Delete" = "shutdown now";
    # sleep is necessary for allowing Awesome to release the keyboard for grabbing.
    "Print" = lib.getExe (pkgs.writeShellScriptBin "copy-screenshot" ''
      sleep 0.2s
      ${lib.getExe scrot} --select --file - | \
          ${lib.getExe xclip} -selection clipboard -target image/png
    '');
    "W-f" = "${lib.getExe librewolf-unfocus}";
    "W-l" = "${lib.getExe' lightlocker "light-locker-command"} --lock";
    "W-p" = "${lib.getExe autorandr} --change";
    "W-t" = "${lib.getExe' xfce.xfce4-terminal "xfce4-terminal"}";
    "W-S-f" = "${lib.getExe config.programs.librewolf.finalPackage} --private-window";
    "XF86AudioMute" = "${lib.getExe pamixer} --toggle-mute";
    "XF86AudioLowerVolume" = "${lib.getExe pamixer} --decrease 2";
    "XF86AudioRaiseVolume" = "${lib.getExe pamixer} --increase 2";
    "XF86AudioPlay" = "${lib.getExe playerctl} play-pause";
    "XF86MonBrightnessUp" = "${lib.getExe brightnessctl} set +2%";
    "XF86MonBrightnessDown" = "${lib.getExe brightnessctl} set 2%-";
  };

  # Windows with the listed WM_CLASS should be maximized by default.
  maximizedWmClasses = [ "Com.github.xournalpp.xournalpp" "librewolf" "Pcmanfm" "Pulsar" "VSCodium" ];
in

{

  imports = let
    wmArgs = args // { inherit appMenu autostart globalApplicationKeybinds maximizedWmClasses; };
  in [
    ./../modules/applications/mimeApps.nix
    ./../modules/applications/nitrogen.nix
    ./../modules/applications/openbox.nix
    ./../modules/system/writableHomeFile.nix
    ./browser.nix
    ./devtools.nix
    (import ./rofi.nix (args // { inherit appMenu; }))
    (import ./wms/awesome.nix wmArgs)
    (import ./wms/openbox.nix wmArgs)
  ];

  # Patches for various desktop applications.
  # - Changes the window behaviour of Feh to have a better viewing experience.
  # - Adds TeX dependency for Gummi.
  # - Makes Blueman's icon change when a device is connected.
  nixpkgs.overlays = [(final: prev: {
    feh = prev.feh.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./../patches/feh-scaling.patch ];
    });
    gummi = let
      texlivePackages = pkgs: builtins.listToAttrs (lib.imap0
        (index: lib.nameValuePair (builtins.toString index))
        (config.customization.gummiTexlivePackages pkgs.texlive)
      );
    in prev.symlinkJoin {
      name = "gummi";
      paths = with prev; [ gummi (texlive.combine (texlivePackages prev)) ];
    };
    papirus-icon-theme = prev.papirus-icon-theme.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./../patches/icons-blueman.patch ];
    });
  })];

  # Allows some unfree packages for isolation.
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) (config.customization.global.allowedUnfreePackages);

  # Some nice icons for applications, files, and the like.
  home.file.".icons/default/index.theme".text = lib.generators.toINI { } {
    "icon theme" = { Inherits = "Bibata-Modern-Amber"; };
  };

  # Uses a more readable color scheme, as the texts blend in with the GTK theme.
  xdg.configFile."gummi/gummi.ini".text = lib.generators.toINI { } {
    Editor.style_scheme = "oblivion";
  };

  # Adds and orders IBus engines to include RIME.
  dconf.settings."desktop/ibus/general" = with lib.hm.gvariant; rec {
    engines-order = mkArray type.string [ "xkb:us::eng" "rime" ];
    preload-engines = engines-order;
  };

  # Adds Cantonese input method.
  xdg.configFile."ibus/rime/default.custom.yaml" = {
    text = lib.generators.toYAML { } {
      patch.schema_list = [{ schema = "jyut6ping3_ipa"; }];
    };
  };

  # Sets default database file and dark theme.
  home.writableFile = lib.mkIf (config.customization.persistence.kdbx != null)
      (lib.mkMerge (builtins.map (path: {
    "${path}/keepassxc/keepassxc.ini".source = pkgs.writeText "keepass-ini" (
      lib.generators.toINI { } {
        General = rec {
          ConfigVersion = 2;
          LastDatabases = config.customization.persistence.kdbx;
          LastActiveDatabases = LastDatabases;
          LastOpenedDatabases = LastDatabases;
        };
        GUI = {
          ApplicationTheme = "dark";
          CompactMode = true;
        };
      }
    );
  }) (with config.xdg; [ cacheHome configHome ])));

  # Disables trash and specifies terminal emulator for quick access in directories.
  xdg.configFile."libfm/libfm.conf".text = lib.generators.toINI { } (lib.updateManyAttrsByPath [
    { path = [ "config" "use_trash" ]; update = old: 0; }
    {
      path = [ "config" "terminal" ];
      update = old: "${lib.getExe' pkgs.xfce.xfce4-terminal "xfce4-terminal"}";
    }
  ] (builtins.fromTOML (builtins.readFile "${pkgs.libfm}/etc/xdg/libfm/libfm.conf")));

  # Uses dark theme and monospace font for Mousepad.
  xdg.configFile."Mousepad/settings.conf".text = lib.generators.toINI { } {
    "org/xfce/mousepad/preferences/view" = {
      word-wrap = true;
      use-default-monospace-font = false;
      font-name = "Noto Sans Mono CJK HK Regular 12";

      show-line-numbers = true;
      color-scheme = "oblivion";
    };
  };

  # Uses Pipewire native volume mixer.
  dconf.settings."apps/volctl".mixer-command = lib.getExe pkgs.pwvucontrol;

  # Uses big pen icon and highlighting for higher visibility.
  # PDF template changed to get rid of the "_annotated" suffix.
  xdg.configFile."xournalpp/settings.xml".source = xmlAttrset.createOrdered rec {
    list = let
      entry = name: value: lib.nameValuePair "property" {
        "@name" = name;
        "@value" = value;
      };
    in lib.attrsets.mapAttrsToList entry {
      stylusCursorType = "big";
      highlightPosition = "true";
      defaultPdfExportName = "%{name}";
    };
    filepath = xmlAttrset.createRoot root null;
    root = "settings";
    useNs = false;
  };

  # Sets various GTK themes and shortcuts in file manager.
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Amber";
    };
    theme = {
      package = pkgs.arc-theme;
      name = "Arc-Dark";
    };
    gtk3.bookmarks = [
      "file:/// Root"
      "file:///mnt Mountpoint"
    ];
  };

  # Sets the wallpaper with a sensible zooming mode.
  programs.nitrogen = lib.mkIf (config.customization.persistence.wallpaper != null) {
    enable = true;
    file = config.customization.persistence.wallpaper;
    mode = "zoomed-fill";
  };

  # Defines associations so that no "Open With..." prompt is neccessary.
  custom.mimeApps = {
    enable = true;
    customMimeTypes = [ "kdbx" "xopp" ];
    defaultApplications = let
      pair = lib.nameValuePair;
      vlcDesktopItem = pkgs.makeDesktopItem {
        name = "vlc-focus";
        desktopName = "VLC media player";
        exec = "${lib.getExe vlc-focus} %U";
      };
      editorEntry = lib.optionalAttrs (config.customization.codeEditor != null) {
        "inode/directory" = if config.customization.codeEditor == "pulsar"
                            then pair "Pulsar" pkgs.pulsar
                            else pair "codium" pkgs.vscodium;
      };
    in with pkgs; {
      "application/pdf" = config.programs.librewolf.finalPackage;
      "application/vnd.appimage" = appimage-run;
      "application/vnd.oasis.opendocument.spreadsheet" = pair "calc" libreoffice-still;
      "application/x-extension-kdbx" = keepassxc;
      "application/x-extension-xopp" = xournalpp;
      "application/x-krita" = krita;
      "application/x-tar" = file-roller;
      "application/zip" = file-roller;
      "image/jpeg" = feh;
      "image/png" = feh;
      "text/plain" = pair "org.xfce.mousepad" xfce.mousepad;
      "video/mp4" = pair "vlc-focus" vlcDesktopItem;
      "video/webm" = pair "vlc-focus" vlcDesktopItem;

      "application/vnd.sqlite3" = sqlitebrowser;
      "application/xml" = pair "org.xfce.mousepad" xfce.mousepad;
      "text/x-tex" = gummi;
    } // editorEntry;
  };

}
