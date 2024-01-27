{ config, lib, pkgs, ... }:

# MIME type configurations with custom extension support.
# Requires `xmlAttrset.nix` for generating XML documents from expressions.

let
  cfg = config.custom.mimeApps;
  xmlAttrset = pkgs.callPackage ./../utils/xmlAttrset.nix { };
  isPackage = value: lib.isDerivation value || lib.isStorePath value;

  alternateNameModule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Alternate name of the desktop file.";
      };
      value = lib.mkOption {
        type = lib.types.package;
        description = "Package that owns the desktop file.";
      };
    };
  };
in

{
  options.custom.mimeApps = {
    enable = lib.mkEnableOption "wrapper for specifying default apps";

    customMimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Custom MIME types to register.";
    };

    defaultApplications = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.package alternateNameModule);
      default = { };
      description = "MIME type to package mapping.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.map (value:
      if isPackage value
      then value
      else value.value
    ) (builtins.attrValues cfg.defaultApplications);

    xdg.dataFile = lib.mkMerge (builtins.map (ext: {
      "mime/packages/user-extension-${ext}".source = xmlAttrset.createOrdered rec {
        list = [(lib.nameValuePair "mime-type" {
          "@type" = "application/x-extension-${ext}";
          comment."text()" = "${ext} file";
          glob."@pattern" = "*.${ext}";
        })];
        filepath = xmlAttrset.createRoot root "http://www.freedesktop.org/standards/shared-mime-info";
        root = "mime-info";
        useNs = true;
      };
    }) cfg.customMimeTypes);

    xdg.mimeApps = {
      enable = true;
      defaultApplications = builtins.mapAttrs (name: value:
        if isPackage value && value ? pname
        then "${value.pname}.desktop"
        else "${value.name}.desktop"
      ) cfg.defaultApplications;
    };
  };
}
