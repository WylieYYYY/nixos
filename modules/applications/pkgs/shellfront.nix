{ pkgs, stdenv, fetchFromGitLab, ... }:

# Simple frontend for terminal applications and Linux shell scripts.

stdenv.mkDerivation rec {
  pname = "shellfront";
  version = "5e3b4c4d935d21afe057104a6ede6625cce147ee";

  nativeBuildInputs = with pkgs; [ autoreconfHook pkg-config ];
  buildInputs = with pkgs; [ gtk3 vte ];
  src = fetchFromGitLab {
    owner = "WylieYYYY";
    repo = pname;
    rev = version;
    sha256 = "vD4gh/NCNGxx1WzNvnk//b77foviN1KBinARca5urq0=";
  };

  buildPhase = ''
    NIX_CFLAGS_COMPILE="$(pkg-config --cflags gtk+-3.0 vte-2.91) $NIX_CFLAGS_COMPILE"
    make
  '';

  meta.mainProgram = pname;
}
