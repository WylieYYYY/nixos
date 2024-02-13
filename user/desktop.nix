args@{ persist, config, lib, pkgs, ... }:

# Adds desktop applications, with some MIME and keybind settings.
# Requires `xmlAttrset.nix` for generating XML documents for Openbox.  
# Requires `userForward.nix` if isolated applications are used.
# Requires `repeatableINI.nix` for generating configurations for Tint2.
# Parameters:
# - persist: Attribute set of persisting settings.
#   - allowedUnfreePackages?: Some unfree package names to allow and isolate.
#   - browserPersistPath?: Persisting directory for browser.
#     - expects: extensions.json, extension-settings.json
#   - containerSuffixes?: Attribute set of container names to their suffixes.
#     - Work?: Suffixes for the work container.
#   - gitUserEmail?: Default email associated with Git.
#   - gitUserName?: Default user name associated with Git.
#   - hostname?: Display name for the top-left corner of the desktop.
#   - isolatedEntries?: Function yielding an attribute set of user names to isolated menu entries.
#     - expects: { lib, pkgs, ... }:
#         { <username> = { name = <application name>; value = <command>; }, ... }
#   - kdbxPath?: Path to the Keepass database for KeepassXC and Keepmenu.
#   - mouseAllowedDomains?: Domains that are excluded from Tridactyl's no mouse mode.
#   - useCubicleExtension?: Whether the browser persisting directory has a build of Cubicle to link.
#   - wallpaperPath?: Path to a wallpaper file for Nitrogen.

let
  xmlAttrset = pkgs.callPackage ./../modules/utils/xmlAttrset.nix { };

  # Browser by default focuses to the address bar on launch,
  # which makes the Tridactyl extension difficult to use.
  librewolf-unfocus = let
    xdotool = lib.getExe pkgs.xdotool;
  in pkgs.writeShellScriptBin "librewolf-unfocus" ''
    ${lib.getExe' pkgs.librewolf "librewolf"} $@ &
    while ${xdotool} getwindowfocus getwindowname | grep --invert-match 'LibreWolf'; do
      sleep 0.1s
    done
    ${xdotool} key 'F6'
  '';

  # Application menu that is declared as an expression.
  # Translated for Rofi and Openbox.
  appMenu = let
    entry = lib.nameValuePair;
    # generates isolated application entries to forward calls to specific users.
    isolatedEntries = lib.optionals (persist ? isolatedEntries) (let
      userForward = userArgs: pkgs.callPackage ./../modules/system/userForward.nix userArgs;
    in lib.mapAttrsToList (name: value:
      entry value.name (userForward { user = name; command = value.value; })
    ) (persist.isolatedEntries { inherit lib pkgs; }));
  in with pkgs; [
    "Applications"
    (entry "Accessories" [
      (entry "Archive Manager" gnome.file-roller)
      (entry "Mousepad" (lib.getExe' xfce.mousepad "mousepad"))
      (entry "Password Manager" (lib.getExe' keepassxc "keepassxc"))
    ])
    (entry "Internet" [
      (entry "LibreWolf" librewolf-unfocus)
    ])
  ] ++ lib.optionals (persist ? isolatedEntries) [(entry "Isolated" isolatedEntries)] ++ [
    (entry "Multimedia" [
      (entry "Krita" (lib.getExe' krita "krita"))
      (entry "VLC" (lib.getExe' vlc "vlc"))
    ])
    (entry "Work" [
      (entry "Gummi" (lib.getExe' gummi "gummi"))
      (entry "LibreOffice" (lib.getExe' libreoffice-still "libreoffice"))
      (entry "VSCodium" vscodium)
      (entry "Xournal++" (lib.getExe' xournalpp "xournalpp"))
    ])
    (entry "File Manager" pcmanfm)
    "System"
    (entry "Terminal" (lib.getExe' xfce.xfce4-terminal "xfce4-terminal"))
    (entry "Reconfigure" { action."@name" = "Reconfigure"; })
    ""
    (entry "Log Out" { action."@name" = "Exit"; })
    (entry "Shutdown" "shutdown now")
  ];
in

{

  imports = [
    ./../modules/applications/mimeApps.nix
    (import ./devtools.nix (args // { inherit persist; }))
    (import ./rofi.nix (args // { inherit appMenu persist; }))
  ]
  ++ lib.optional (persist ? browserPersistPath)
      (import ./browser.nix (args // { inherit persist; }));

  # Patches for various desktop applications.
  # - Changes the window behaviour of Feh to have a better viewing experience.
  # - Adds TeX dependency for Gummi.
  # - Makes Blueman's icon change when a device is connected.
  nixpkgs.overlays = [(final: prev: {
    feh = prev.feh.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./../patches/feh-scaling.patch ];
    });
    gummi = prev.symlinkJoin {
      name = "gummi";
      paths = [ prev.gummi prev.texlive.combined.scheme-basic ];
    };
    papirus-icon-theme = prev.papirus-icon-theme.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./../patches/icons-blueman.patch ];
    });
  })];

  xsession = {
    enable = true;
    windowManager.command = lib.getExe' pkgs.openbox "openbox-session";
  };

  # Allows some unfree packages for isolation.
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) (persist.allowedUnfreePackages or [ ]);

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
  home.writableFile = lib.mkIf (persist ? kdbxPath) (lib.mkMerge (builtins.map (path: {
    "${path}/keepassxc/keepassxc.ini".source = pkgs.writeText "keepass-ini" (
      lib.generators.toINI { } {
        General = rec {
          ConfigVersion = 2;
          LastDatabases = builtins.toString persist.kdbxPath;
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
      font-name = "Fira Code 12";

      show-line-numbers = true;
      color-scheme = "oblivion";
    };
  };

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
  programs.nitrogen = lib.mkIf (persist ? wallpaperPath) {
    enable = true;
    file = persist.wallpaperPath;
    mode = "zoomed-fill";
  };

  programs.openbox = {
    enable = true;
    themePackages = [ pkgs.numix-gtk-theme ];
    # starts taskbar and applets and enables locking.
    # inherits display settings from `autorandr`.
    autostart = let
      displaySettings = lib.concatStringsSep "\n" (lib.attrValues
          config.programs.autorandr.hooks.postswitch);
    in with pkgs; ''
      ${displaySettings}
      ${lib.getExe' tint2 "tint2"} &
      ${lib.getExe' cbatticon "cbatticon"} &
      ${lib.getExe' networkmanagerapplet "nm-applet"} &
      ${lib.getExe' blueman "blueman-applet"} &
      { sleep 2; ${lib.getExe volctl} & }
      ${lib.getExe' lightlocker "light-locker"} &
    '';
    # use the menu expression as-is, easy.
    menu = appMenu;
    keybinds = with pkgs; let
      windowCycle = {
        raise."text()" = "yes";
        linear."text()" = "yes";
        interactive."text()" = "no";
      };
      # Snapping to the left or right.
      windowSnap = x: {
        "@name" = "If";
        query.maximized."text()" = "yes";
        "then".action = [
          { "@name" = "Unmaximize"; }
          {
            "@name" = "MoveResizeTo";
            x."text()" = x;
            y."text()" = "0";
            width."text()" = "50%";
            height."text()" = "100%";
          }
        ];
        "else".action."@name" = "Maximize";
      };
    in {
      # shortcuts and unusual keybinds.
      "A-d" = { "@name" = "Close"; };
      "A-f" = "${lib.getExe rofi} -show filebrowser";
      "A-j" = windowCycle // { "@name" = "PreviousWindow"; };
      "A-k" = windowCycle // { "@name" = "NextWindow"; };
      "A-S-j" = windowSnap "0";
      "A-S-k" = windowSnap "-0";
      "F1" = "${lib.getExe rofi} -show 'open application'";

      # some more common keybinds.
      "C-A-Delete" = "shutdown now";
      "Print" = "${lib.getExe scrot} --select --file ~/screenshot.png";
      "W-f" = "${lib.getExe' librewolf "librewolf"}";
      "W-l" = "${lib.getExe' lightlocker "light-locker-command"} --lock";
      "W-p" = "${lib.getExe autorandr} --change";
      "W-t" = "${lib.getExe' xfce.xfce4-terminal "xfce4-terminal"}";
      "W-S-f" = "${lib.getExe' librewolf "librewolf"} --private-window";
      "XF86AudioMute" = "${lib.getExe pamixer} --toggle-mute";
      "XF86AudioLowerVolume" = "${lib.getExe pamixer} --decrease 2";
      "XF86AudioRaiseVolume" = "${lib.getExe pamixer} --increase 2";
      "XF86AudioPlay" = "${lib.getExe playerctl} play-pause";
      "XF86MonBrightnessUp" = "${lib.getExe brightnessctl} set +2%";
      "XF86MonBrightnessDown" = "${lib.getExe brightnessctl} set 2%-";
    };
    rc = {
      # follows `themePackages` above.
      theme.name."text()" = "Numix";
      # sets one desktop with hostname on the top-left corner.
      desktops = {
        number."text()" = 1;
        names.name = lib.optional (persist ? hostname) { "text()" = persist.hostname; };
      };
      # opens some applications maximized.
      applications.application = (builtins.map (class: {
        "@class" = class;
        "@type" = "normal";
        maximized."text()" = "yes";
      }) [ "Com.github.xournalpp.xournalpp" "librewolf" "Pcmanfm" "VSCodium" ]);
    };
  };

  # Customizes the taskbar.
  # Puts on top, removes top-left launchers, and sets clock format.
  programs.tint2 = {
    enable = true;
    extraConfig = pkgs.callPackage ./../modules/utils/repeatableINI.nix {
      changeSet = {
        panel_position = "top center horizontal";
        launcher_item_app = null;
        time1_format = "%H:%M.%S";
        time2_format = "%Y-%m-%d";
        clock_lclick_command = lib.getExe (pkgs.writeShellScriptBin "calendar" ''
          ${lib.getExe pkgs.shellfront} -Tps 21x8 -g 3 -c 'echo -n \
              "$(${lib.getExe' pkgs.ncurses "tput"} bold; \
              ${lib.getExe' pkgs.expect "unbuffer"} cal | \
              ${lib.getExe pkgs.lolcat} -ft -) "; sleep infinity'
        '');
      };
      iniString = builtins.readFile "${pkgs.tint2}/etc/xdg/tint2/tint2rc";
    };
  };
 
  # Defines associations so that no "Open With..." prompt is neccessary.
  custom.mimeApps = {
    enable = true;
    customMimeTypes = [ "kdbx" "xopp" ];
    defaultApplications = let
      pair = lib.nameValuePair;
    in with pkgs; {
      "application/pdf" = librewolf;
      "application/vnd.appimage" = appimage-run;
      "application/vnd.oasis.opendocument.spreadsheet" = pair "calc" libreoffice-still;
      "application/x-extension-kdbx" = keepassxc;
      "application/x-extension-xopp" = xournalpp;
      "application/x-krita" = krita;
      "application/x-tar" = gnome.file-roller;
      "application/zip" = gnome.file-roller;
      "image/jpeg" = feh;
      "image/png" = feh;
      "text/plain" = pair "org.xfce.mousepad" xfce.mousepad;
      "video/mp4" = vlc;

      "application/vnd.sqlite3" = sqlitebrowser;
      "application/xml" = pair "org.xfce.mousepad" xfce.mousepad;
      "text/x-tex" = gummi;
    };
  };

}
