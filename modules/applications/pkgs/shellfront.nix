{ pkgs, stdenv, fetchFromGitLab, ... }:

# Simple frontend for terminal applications and Linux shell scripts.

stdenv.mkDerivation rec {
  pname = "shellfront";
  version = "c091997f724e89a86f600ae9abc3ac944985b193";

  nativeBuildInputs = with pkgs; [ autoreconfHook pkg-config ];
  buildInputs = with pkgs; [ gtk3 vte ];
  src = fetchFromGitLab {
    owner = "WylieYYYY";
    repo = pname;
    rev = version;
    sha256 = "4D2uNfoePDIWD2X/Jv+UCtBxX3Gl2hXPmE/sAR+iRPk=";
  };

  buildPhase = ''
    NIX_CFLAGS_COMPILE="$(pkg-config --cflags gtk+-3.0 vte-2.91) $NIX_CFLAGS_COMPILE"
    make
  '';

  meta.mainProgram = pname;
}
