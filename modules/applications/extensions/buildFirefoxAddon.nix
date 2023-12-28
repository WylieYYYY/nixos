{ pname, version, addonId, src, meta ? { }, stdenv, ... }:

# Builds a Firefox addon and installs it into a shared extension folder.
# Parameters:
# - pname: Passthrough to `mkDerivation`.
# - version: Passthrough to `mkDerivation`.
# - addonId: Addon ID of the extension for naming the file.
# - src: Passthrough to `mkDerivation`.
# - meta: Passthough to `mkDerivation` with `addonId` added.
# Returns: Derivation of the extension to be consumed by Nix.

stdenv.mkDerivation {
  inherit pname version src;

  meta = meta // { inherit addonId; };

  buildCommand = ''
    dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
    mkdir --parent "$dst"
    install --mode 644 "$src" "$dst/${addonId}.xpi"
  '';
}
