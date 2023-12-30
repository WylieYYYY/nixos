{ lib, pkgs, ... }:

# Cubicle extension for Firefox.
# todo: Replace stub with a real source once published.

pkgs.callPackage ./buildFirefoxAddon.nix {
  pname = "cubicle";
  version = "0.1.0";
  addonId = "{69b2cfb8-4568-499a-9c38-858d8499f71c}";
  src = pkgs.writeText "cubicle-stub" "This is an extension stub.";
}
