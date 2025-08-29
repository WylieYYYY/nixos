{ appMenu, config, lib, pkgs, ... }:

# Adds Rofi, Keepmenu, and related applications.
# Creates an application in Rofi using the same structure as the Openbox configuration.
# - Patches `Keepmenu` to allow adaptive autotyping by the fields available.
# Parameters:
# - appMenu: Openbox pipemenu configuration.

let
  isPackage = value: lib.isDerivation value || lib.isStorePath value;

  # Flattens structures to create a flat application menu.
  flattenEntryRecursive = entry:
    # ignore if it is a separator or a special Openbox action.
    if builtins.isString entry || (!(isPackage entry.value) && builtins.isAttrs entry.value)
      then [ ]
    # recurse and flatten if it is a sub-menu.
    else if builtins.isList entry.value
      then lib.flatten (builtins.map flattenEntryRecursive entry.value)
    # otherwise it should be executable, either a package or a command string.
    else [ (lib.nameValuePair (lib.escapeShellArg entry.name) entry.value) ];

  # Flattens the given menu and prepends a Keepmenu entry.
  flattenedMenu = lib.optional (config.customization.persistence.kdbx != null) (
    lib.nameValuePair (lib.escapeShellArg "Fill Password") (lib.getExe' pkgs.keepmenu "keepmenu")
  ) ++ (lib.flatten (builtins.map flattenEntryRecursive appMenu));

  # Creates counted Rofi entries and adds hidden search terms by derivation name or path.
  menuArgs = lib.imap0 (index: entry: let
    meta = lib.escapeShellArg (if lib.isDerivation entry.value
                               then entry.value.name
                               else lib.last (builtins.split "/" entry.value));
  in ''printf "%s\0info\x1f%s\x1fmeta\x1f%s\n" ${entry.name} ${builtins.toString index} ${meta}''
  ) flattenedMenu;

  # Gets all executable paths and escape them for putting into a Bash array.
  menuCommands = builtins.map (entry: lib.escapeShellArg (
    if isPackage entry.value
    then lib.getExe entry.value
    else entry.value
  )) flattenedMenu;

  # Creates a shell script that is recognizable by Rofi.
  openApplicationMenu = pkgs.writeShellScriptBin "rofi-appmenu" ''
    if [ $# -eq 0 ]; then
      ${lib.concatStringsSep "\n" menuArgs}
    else
      commands=(${lib.concatStringsSep " " menuCommands})
      coproc (''${commands[$ROFI_INFO]} >/dev/null 2>&1)
    fi
  '';
in

{

  # Patched Keepmenu.
  # - Adds `{AT:ADAPTIVE}` to skip `{USERNAME}{TAB}` if there is no username field.
  # - Removes extra return key tap.
  nixpkgs.overlays = [(final: prev: {
    keepmenu = prev.keepmenu.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./../patches/keepmenu-adaptive-typing.patch ];
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/keepmenu --set PATH \
            ${lib.makeBinPath (with pkgs; [ rofi xclip xdotool ])}
      '';
    });
  })];

  # Registers Keepass database, Rofi, and adaptive autotype for Keepmenu.
  xdg.configFile."keepmenu/config.ini" = lib.mkIf (config.customization.persistence.kdbx != null) {
    text = lib.generators.toINI { } {
      dmenu.dmenu_command = "${lib.getExe pkgs.rofi} -dmenu -i";
      dmenu_passphrase.obscure = "True";
      database = {
        database_1 = config.customization.persistence.kdbx;
        autotype_default = "{AT:ADAPTIVE}";
        pw_cache_period_min = 60;
        type_library = "xdotool";
      };
    };
  };

  programs.rofi = {
    enable = true;
    location = "bottom-left";
    theme = "Arc-Dark";
    extraConfig.modes = "filebrowser,window,open application:${lib.getExe openApplicationMenu}";
  };

}
