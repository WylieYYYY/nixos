{ pkgs, ... }:

# 7TV extension for Firefox.

pkgs.callPackage ./buildFirefoxAddon.nix rec {
  pname = "7tv";
  version = "3.0.9";
  addonId = "moz-addon-prod@7tv.app";
  src = builtins.fetchurl {
    url = "https://extension.7tv.gg/v${version}/ext.xpi";
    sha256 = "0smkb7b8cyfnp6p6b4mwbps44k9akrka3c515cq5d11d467c0qnz";
  };
}
