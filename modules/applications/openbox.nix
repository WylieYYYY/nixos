{ config, lib, pkgs, ... }:

# Openbox configurations.

let
  cfg = config.programs.openbox;
  xmlAttrset = pkgs.callPackage ./../utils/xmlAttrset.nix { };
  pair = lib.nameValuePair;

  # Generates structures to be consumed by the generator.
  # Gathering packages to make them available in the user environment.
  generateWrappedEntry = let
    wrapNode = node: {
      nodes = [ node ];
      packages = [ ];
    };
    isPackage = value: lib.isDerivation value || lib.isStorePath value;
  in entry:
    # string entry denotes a separator, make the label if given.
    if builtins.isString entry
      then wrapNode (pair "separator" (
        lib.optionalAttrs (entry != "") { "@label" = entry; }
      ))
    # normal attribute set should be inserted without modification for special actions.
    else if !(isPackage entry.value) && builtins.isAttrs entry.value
      then wrapNode (pair "item" ({
        "@label" = entry.name;
      } // entry.value))
    # lists are sub-menus and will be accummulated by the other function.
    else if builtins.isList entry.value
      then let
        menuItem = generateMenuRecursive entry.value;
      in wrapNode (pair "menu" ([
        (pair "@id" (builtins.hashString "md5"
            (builtins.toString entry.name)))
        (pair "@label" entry.name)
      ] ++ menuItem.nodes)) // { packages = menuItem.packages; }
    # either it is a package, for which an executable should be found,
    # or it is a string and should be executed as-is.
    else let
      valueIsPackage = isPackage entry.value;
      command = if valueIsPackage then lib.getExe entry.value else entry.value;
    in (wrapNode (pair "item" {
      "@label" = entry.name;
      action = {
        "@name" = "Execute";
        command."text()" = command;
      };
    })) // { packages = lib.optional valueIsPackage entry.value; };

  # Generates the full menu or sub-menus by accummulating the generated nodes and packages.
  generateMenuRecursive = lib.foldr (entry: acc: let
    menuItem = generateWrappedEntry entry;
  in {
    nodes = menuItem.nodes ++ acc.nodes;
    packages = menuItem.packages ++ acc.packages;
  }) { nodes = [ ]; packages = [ ]; };
in

{
  options.programs.openbox = {
    enable = lib.mkEnableOption "openbox, a highly configurable window manager";

    autostart = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = "Content of the autostart script.";
    };

    themePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of packages providing the theme.";
    };

    menu = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.anything);
      default = null;
      apply = list: let
        menuItem = generateMenuRecursive list;
      in {
        nodes = [
          (pair "menu" ([
            (pair "@id" "root-menu")
            (pair "@label" "Openbox 3")
          ] ++ menuItem.nodes))
        ];
        packages = menuItem.packages;
      };
      description = "Structured Openbox menu.";
    };

    keybinds = lib.mkOption {
      type = with lib.types; attrsOf (either nonEmptyStr attrs);
      default = { };
      apply = set: {
        # suppress default entries that do not work.
        keyboard."keybind[@key='W-e']" = null;
        # either it is a string that can be executed as-is,
        # or it is a special action that should be inserted without modification.
        keyboard.keybind = lib.foldlAttrs (acc: name: value: acc ++ [{
          "@key" = name;
          action = if builtins.isString value
                   then {
                     "@name" = "Execute";
                     command."text()" = value;
                   }
                   else value;
        }]) [ ] set;
      };
      description = "Attribute set of keybinds to commands.";
    };

    rc = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Structured Openbox settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.themePackages ++ [ pkgs.openbox ];

    xdg.configFile."openbox/autostart" = lib.mkIf (cfg.autostart != null) {
      source = lib.getExe (pkgs.writeShellScriptBin "openbox-autostart" cfg.autostart);
    };

    xdg.configFile."openbox/menu.xml" = lib.mkIf (cfg.menu != null) {
      source = xmlAttrset.createOrdered rec {
        list = cfg.menu.nodes;
        filepath = xmlAttrset.createRoot root "http://openbox.org/3.4/menu";
        root = "openbox_menu";
        useNs = true;
      };
    };

    xdg.configFile."openbox/rc.xml".source = xmlAttrset.applyUnordered {
      set = cfg.rc // cfg.keybinds;
      filepath = "${pkgs.openbox}/etc/xdg/openbox/rc.xml";
      root = "openbox_config";
      useNs = true;
    };
  };
}
