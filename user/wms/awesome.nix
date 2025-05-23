{ appMenu, autostart, globalApplicationKeybinds, maximizedWmClasses, config, lib, pkgs, ... }:

# Adds Awesome with Lua libraries and source files.
# Reuses the same configuration structures as the Openbox configurations.
# Parameters:
# - appMenu: Openbox pipemenu configuration.
# - autostart: Content of the autostart script.
# - globalApplicationKeybinds: Attribute set of keybinds to commands,
#   accepts only string values.
# - maximizedWmClasses: List of WM_CLASS,
#   windows with any of the classes will be maximized by default.

let
  isPackage = value: lib.isDerivation value || lib.isStorePath value;

  # Removes Openbox specific entries and converts the rest of the menu to Awesome's format.
  filterFormatRegularEntryRecursive = entry:
    # ignore if it is a separator or a special Openbox action.
    if builtins.isString entry || (!(isPackage entry.value) && builtins.isAttrs entry.value)
      then [ ]
    # recurse and convert if it is a sub-menu.
    else if builtins.isList entry.value
      then [ [ entry.name (builtins.foldl' (acc: subEntry:
        acc ++ filterFormatRegularEntryRecursive subEntry
      ) [ ] entry.value) ] ]
    # gets the executable path if it is a package.
    else if isPackage entry.value
      then [ [ entry.name (lib.getExe entry.value) ] ]
    # otherwise it is a command string which can be used as-is.
    else [ [ entry.name entry.value ] ];

    # Starts converting the menu into Awesome's format.
    filteredAppMenu = builtins.foldl' (acc: subEntry:
      acc ++ filterFormatRegularEntryRecursive subEntry
    ) [ ] appMenu;

    # Replaces meta key name in the global keybinds.
    metaReplacedGlobalApplicationKeybinds = lib.mapAttrs' (name: value:
      lib.nameValuePair "${builtins.replaceStrings [ "W-" ] [ "M-" ] name}" value
    ) globalApplicationKeybinds;
in

{

  # Bundles WM common configurations JSON file with Lua source files.
  xdg.configFile = lib.mkIf (
    config.customization.windowManager == "awesome"
  ) {
    "awesome".source = pkgs.stdenv.mkDerivation {
      name = "awesome-config-bundled";

      srcs = [
        (builtins.path { name = "awesome-config"; path = ./awesome; })
        (pkgs.writeText "wm-common-json" (builtins.toJSON {
          app_menu = filteredAppMenu;
          global_application_keybinds = metaReplacedGlobalApplicationKeybinds;
          maximized_wm_classes = maximizedWmClasses;
        }))
        (pkgs.stdenv.mkDerivation {
          name = "awesome-snap";
          src = "${pkgs.awesome}/share/awesome/lib/awful/mouse";
          patches = [ ./../../patches/awesome-snap-maximize-both-axis.patch ];
          buildPhase = "install --mode 444 -D --target-directory $out snap.lua";
        })
      ];

      dontUnpack = true;

      buildPhase = ''
        srcs=($srcs)
        install --mode 444 -D --target-directory $out ''${srcs[0]}/*
        install --mode 444 ''${srcs[1]} $out/wm-common.json
        install --mode 444 ''${srcs[2]}/snap.lua $out/snap.lua
      '';
    };
  };

  # Adds Luarocks libraries and autostart.
  xsession = let
    getLuaPath = lib: dir: "${lib}/${dir}/lua/${pkgs.awesome.lua.luaversion}";
    makeSearchPath = lib.concatMapStrings (path:
      " --search ${getLuaPath path "share"} --search ${getLuaPath path "lib"}"
    );
    luaPackages = with pkgs.lua52Packages; [ awesome-ez cjson ];
  in lib.mkIf (config.customization.windowManager == "awesome") {
    enable = true;
    windowManager.command = ''
      ${lib.getExe' pkgs.awesome "awesome"}${makeSearchPath luaPackages} &
      pid=$!
      ${autostart}
      wait $pid
    '';
  };

}
