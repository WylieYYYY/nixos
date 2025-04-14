{ appMenu, autostart, globalApplicationKeybinds, maximizedWmClasses, config, lib, pkgs, ... }:

# Adds Openbox with its configurations.
# Parameters:
# - appMenu: Openbox pipemenu configuration.
# - autostart: Content of the autostart script.
# - globalApplicationKeybinds: Attribute set of keybinds to commands,
#   prefer string values for compatibility with other window manager.
#   However, Openbox directive structures are acceptable.
# - maximizedWmClasses: List of WM_CLASS,
#   windows with any of the classes will be maximized by default.

{

  programs.openbox = lib.mkIf (config.customization.windowManager == "openbox") {
    enable = true;
    themePackages = [ pkgs.numix-gtk-theme ];
    # Additionally starts taskbar apart from standard autostart.
    autostart = ''
      { sleep 2; ${lib.getExe' pkgs.tint2 "tint2"} & } &
      ${autostart}
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
      "A-j" = windowCycle // { "@name" = "PreviousWindow"; };
      "A-k" = windowCycle // { "@name" = "NextWindow"; };
      "A-S-j" = windowSnap "0";
      "A-S-k" = windowSnap "-0";
      "C-W-t" = { "@name" = "ToggleAlwaysOnTop"; };
    } // globalApplicationKeybinds;
    rc = {
      # follows `themePackages` above.
      theme.name."text()" = "Numix";
      # sets one desktop with hostname on the top-left corner.
      desktops = {
        number."text()" = 1;
        names.name = [{
          "text()" = config.customization.global.network.hostname;
        }];
      };
      # opens some applications maximized.
      applications.application = builtins.map (class: {
        "@class" = class;
        "@type" = "normal";
        maximized."text()" = "yes";
      }) maximizedWmClasses;
    };
  };

  # Customizes the taskbar.
  # Puts on top, removes top-left launchers, and sets clock format.
  programs.tint2 = lib.mkIf (config.customization.windowManager == "openbox") {
    enable = true;
    extraConfig = pkgs.callPackage ./../../modules/utils/repeatableINI.nix {
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

  xsession = lib.mkIf (config.customization.windowManager == "openbox") {
    enable = true;
    windowManager.command = lib.getExe' pkgs.openbox "openbox-session";
  };

}
