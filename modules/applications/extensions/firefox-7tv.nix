{ pkgs, fetchurl, ... }:

# 7TV extension for Firefox.

pkgs.callPackage ./buildFirefoxAddon.nix rec {
  pname = "7tv";
  version = "3.1.22";
  addonId = "moz-addon-prod@7tv.app";
  src = fetchurl {
    url = "https://extension.7tv.gg/v${version}/ext.xpi";
    sha256 = "XCH/zPvO5p0DreKTpaUaiJNUcKU5akwktyE7sea/uok=";
  };
}
